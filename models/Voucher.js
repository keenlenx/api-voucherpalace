const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class Voucher {
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM vouchers WHERE 1=1';
    const args = [];

    if (filters.tenant_id) {
      query += ` AND tenant_id = $${args.length + 1}`;
      args.push(filters.tenant_id);
    }

    if (filters.status) {
      query += ` AND status = $${args.length + 1}`;
      args.push(filters.status);
    }

    if (filters.voucher_template_id) {
      query += ` AND voucher_template_id = $${args.length + 1}`;
      args.push(filters.voucher_template_id);
    }

    if (filters.code) {
      query += ` AND code ILIKE $${args.length + 1}`;
      args.push(`%${filters.code}%`);
    }

    if (filters.search) {
      query += ` AND (code ILIKE $${args.length + 1} OR beneficiary_email ILIKE $${args.length + 1} OR beneficiary_phone ILIKE $${args.length + 1})`;
      args.push(`%${filters.search}%`);
      args.push(`%${filters.search}%`);
      args.push(`%${filters.search}%`);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM vouchers WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async getByCode(code) {
    const result = await pool.query('SELECT * FROM vouchers WHERE code = $1', [code]);
    return result.rows[0];
  }

  static async create(data) {
    const { voucher_template_id, tenant_id, original_value, beneficiary_name, beneficiary_email, beneficiary_phone, expires_at, created_by } = data;
    const code = `RFA-${Date.now()}-${Math.random().toString(36).substring(2, 9).toUpperCase()}`;
    
    const result = await pool.query(
      `INSERT INTO vouchers (voucher_template_id, tenant_id, code, original_value, remaining_value, beneficiary_name, beneficiary_email, beneficiary_phone, expires_at, created_by) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
      [voucher_template_id, tenant_id, code, original_value, original_value, beneficiary_name, beneficiary_email, beneficiary_phone, expires_at, created_by]
    );
    return result.rows[0];
  }

  static async update(id, data) {
    const { beneficiary_name, beneficiary_email, beneficiary_phone, status, updated_by } = data;
    const result = await pool.query(
      `UPDATE vouchers SET beneficiary_name = COALESCE($1, beneficiary_name), beneficiary_email = COALESCE($2, beneficiary_email), 
       beneficiary_phone = COALESCE($3, beneficiary_phone), status = COALESCE($4, status), updated_by = $5 WHERE id = $6 RETURNING *`,
      [beneficiary_name, beneficiary_email, beneficiary_phone, status, updated_by, id]
    );
    return result.rows[0];
  }

  static async delete(id) {
    const result = await pool.query('DELETE FROM vouchers WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  }
static async createBulk(vouchersData) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const results = [];
    const batchId = `BATCH-${Date.now()}-${Math.random().toString(36).substring(2, 7).toUpperCase()}`;
    
    for (const data of vouchersData) {
      const code = `RFA-${Date.now()}-${Math.random().toString(36).substring(2, 9).toUpperCase()}`;
      const result = await client.query(
        `INSERT INTO vouchers (voucher_template_id, tenant_id, code, original_value, remaining_value, 
         beneficiary_name, beneficiary_email, beneficiary_phone, expires_at, created_by, batch_id) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
        [data.voucher_template_id, data.tenant_id, code, data.original_value, data.original_value,
         data.beneficiary_name, data.beneficiary_email, data.beneficiary_phone, data.expires_at, data.created_by, batchId]
      );
      results.push(result.rows[0]);
    }
    
    await client.query('COMMIT');
    return { batchId, vouchers: results };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
static async getStats(tenantId, days = 30) {
  const result = await pool.query(`
    SELECT 
      COUNT(*) as total_vouchers,
      COUNT(CASE WHEN status = 'active' THEN 1 END) as active_count,
      COUNT(CASE WHEN status = 'redeemed' THEN 1 END) as redeemed_count,
      COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired_count,
      COALESCE(SUM(original_value), 0) as total_value,
      COALESCE(SUM(remaining_value), 0) as remaining_value,
      COALESCE(SUM(original_value - remaining_value), 0) as redeemed_value,
      COUNT(DISTINCT voucher_template_id) as template_count,
      COUNT(DISTINCT beneficiary_email) as unique_beneficiaries
    FROM vouchers 
    WHERE tenant_id = $1 
    AND created_at >= NOW() - INTERVAL '${days} days'
  `, [tenantId]);
  
  // Daily trend
  const trend = await pool.query(`
    SELECT 
      DATE(created_at) as date,
      COUNT(*) as issued,
      COUNT(CASE WHEN status = 'redeemed' THEN 1 END) as redeemed
    FROM vouchers 
    WHERE tenant_id = $1 
    AND created_at >= NOW() - INTERVAL '${days} days'
    GROUP BY DATE(created_at)
    ORDER BY date DESC
  `, [tenantId]);
  
  return {
    ...result.rows[0],
    trend: trend.rows
  };
}
static async markExpired() {
  const result = await pool.query(`
    UPDATE vouchers 
    SET status = 'expired', updated_at = NOW() 
    WHERE status = 'active' 
    AND expires_at < NOW() 
    RETURNING *
  `);
  return result.rows;
}

static async getExpiringSoon(days = 7, tenantId = null) {
  let query = `
    SELECT * FROM vouchers 
    WHERE status = 'active' 
    AND expires_at IS NOT NULL 
    AND expires_at <= NOW() + INTERVAL '${days} days'
  `;
  const args = [];
  
  if (tenantId) {
    query += ` AND tenant_id = $${args.length + 1}`;
    args.push(tenantId);
  }
  
  query += ' ORDER BY expires_at ASC';
  const result = await pool.query(query, args);
  return result.rows;
}
static async redeem(id, amount, redeemedBy, metadata = {}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Get current voucher with lock
    const voucher = await client.query(
      'SELECT * FROM vouchers WHERE id = $1 FOR UPDATE',
      [id]
    );
    
    if (!voucher.rows[0]) throw new Error('Voucher not found');
    if (voucher.rows[0].status !== 'active') throw new Error('Voucher not active');
    if (parseFloat(voucher.rows[0].remaining_value) < amount) throw new Error('Insufficient balance');
    
    const newRemaining = parseFloat(voucher.rows[0].remaining_value) - amount;
    const newStatus = newRemaining === 0 ? 'redeemed' : 'active';
    
    // Update voucher
    const updated = await client.query(
      `UPDATE vouchers 
       SET remaining_value = $1, status = $2, updated_at = NOW() 
       WHERE id = $3 RETURNING *`,
      [newRemaining, newStatus, id]
    );
    
    // Record redemption
    const redemption = await client.query(
      `INSERT INTO redemptions (voucher_id, amount, previous_balance, new_balance, redeemed_by, metadata)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [id, amount, voucher.rows[0].remaining_value, newRemaining, redeemedBy, metadata]
    );
    
    await client.query('COMMIT');
    return { voucher: updated.rows[0], redemption: redemption.rows[0] };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

static async getRedemptionHistory(id) {
  const result = await pool.query(`
    SELECT r.*, u.email as redeemed_by_email 
    FROM redemptions r
    LEFT JOIN users u ON r.redeemed_by = u.id
    WHERE r.voucher_id = $1
    ORDER BY r.created_at DESC
  `, [id]);
  return result.rows;
}
}


module.exports = Voucher;