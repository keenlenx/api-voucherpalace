const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class Merchant {
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM merchants WHERE 1=1';
    const args = [];

    if (filters.tenant_id) {
      query += ` AND tenant_id = $${args.length + 1}`;
      args.push(filters.tenant_id);
    }

    if (filters.merchant_category) {
      query += ` AND merchant_category = $${args.length + 1}`;
      args.push(filters.merchant_category);
    }

    if (filters.is_active !== undefined) {
      query += ` AND is_active = $${args.length + 1}`;
      args.push(filters.is_active);
    }

    if (filters.search) {
      query += ` AND (merchant_name ILIKE $${args.length + 1} OR merchant_code ILIKE $${args.length + 1})`;
      args.push(`%${filters.search}%`);
      args.push(`%${filters.search}%`);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM merchants WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async create(data) {
    const { tenant_id, merchant_name, merchant_code, merchant_category, contact_person, email, phone, address, latitude, longitude, settlement_period, created_by } = data;
    const result = await pool.query(
      `INSERT INTO merchants (tenant_id, merchant_name, merchant_code, merchant_category, contact_person, email, phone, address, latitude, longitude, settlement_period, created_by) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
      [tenant_id, merchant_name, merchant_code, merchant_category, contact_person, email, phone, address, latitude, longitude, settlement_period || 'weekly', created_by]
    );
    return result.rows[0];
  }

  static async update(id, data) {
    const { merchant_name, merchant_category, email, phone, address, settlement_period, is_active, updated_by } = data;
    const result = await pool.query(
      `UPDATE merchants SET merchant_name = COALESCE($1, merchant_name), merchant_category = COALESCE($2, merchant_category), 
       email = COALESCE($3, email), phone = COALESCE($4, phone), address = COALESCE($5, address), 
       settlement_period = COALESCE($6, settlement_period), is_active = COALESCE($7, is_active), updated_by = $8 WHERE id = $9 RETURNING *`,
      [merchant_name, merchant_category, email, phone, address, settlement_period, is_active, updated_by, id]
    );
    return result.rows[0];
  }

  static async delete(id) {
    const result = await pool.query('DELETE FROM merchants WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  }
}

module.exports = Merchant;