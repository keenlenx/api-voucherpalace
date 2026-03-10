const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class Settlement {
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM settlements WHERE 1=1';
    const args = [];

    if (filters.merchant_id) {
      query += ` AND merchant_id = $${args.length + 1}`;
      args.push(filters.merchant_id);
    }

    if (filters.status) {
      query += ` AND status = $${args.length + 1}`;
      args.push(filters.status);
    }

    if (filters.period_from) {
      query += ` AND period_start >= $${args.length + 1}::date`;
      args.push(filters.period_from);
    }

    if (filters.period_to) {
      query += ` AND period_end <= $${args.length + 1}::date`;
      args.push(filters.period_to);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM settlements WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async create(data) {
    const { merchant_id, period_start, period_end, total_amount, rfa_fees, created_by } = data;
    const settlementNumber = `SETTLE-${Date.now()}`;
    const netPayable = total_amount - rfa_fees;

    const result = await pool.query(
      `INSERT INTO settlements (settlement_number, merchant_id, period_start, period_end, total_amount, rfa_fees, net_payable, created_by) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [settlementNumber, merchant_id, period_start, period_end, total_amount, rfa_fees, netPayable, created_by]
    );
    return result.rows[0];
  }

  static async updateStatus(id, status) {
    const result = await pool.query(
      `UPDATE settlements SET status = $1, paid_at = CASE WHEN $1 = 'paid' THEN NOW() ELSE paid_at END WHERE id = $2 RETURNING *`,
      [status, id]
    );
    return result.rows[0];
  }
}

module.exports = Settlement;