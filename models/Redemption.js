const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class Redemption {
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM redemptions WHERE 1=1';
    const args = [];

    if (filters.voucher_id) {
      query += ` AND voucher_id = $${args.length + 1}`;
      args.push(filters.voucher_id);
    }

    if (filters.merchant_id) {
      query += ` AND merchant_id = $${args.length + 1}`;
      args.push(filters.merchant_id);
    }

    if (filters.status) {
      query += ` AND status = $${args.length + 1}`;
      args.push(filters.status);
    }

    if (filters.date_from) {
      query += ` AND created_at >= $${args.length + 1}::date`;
      args.push(filters.date_from);
    }

    if (filters.date_to) {
      query += ` AND created_at <= $${args.length + 1}::date`;
      args.push(filters.date_to);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM redemptions WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async create(data) {
    const { voucher_id, merchant_id, amount_redeemed, redemption_method, receipt_number, created_by } = data;
    
    // Get current voucher balance
    const voucherResult = await pool.query('SELECT remaining_value FROM vouchers WHERE id = $1', [voucher_id]);
    const previousBalance = voucherResult.rows[0]?.remaining_value || 0;
    const newBalance = Math.max(0, previousBalance - amount_redeemed);

    const result = await pool.query(
      `INSERT INTO redemptions (voucher_id, merchant_id, amount_redeemed, previous_balance, new_balance, redemption_method, receipt_number, created_by) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [voucher_id, merchant_id, amount_redeemed, previousBalance, newBalance, redemption_method, receipt_number, created_by]
    );
    return result.rows[0];
  }

  static async reversal(id, data) {
    const { reversal_reason, reversed_by } = data;
    const result = await pool.query(
      `UPDATE redemptions SET status = 'reversed', reversal_reason = $1, reversed_by = $2, reversed_at = NOW() WHERE id = $3 RETURNING *`,
      [reversal_reason, reversed_by, id]
    );
    return result.rows[0];
  }
}

module.exports = Redemption;