const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class VoucherBatch {
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM voucher_batches WHERE 1=1';
    const args = [];

    if (filters.tenant_id) {
      query += ` AND tenant_id = $${args.length + 1}`;
      args.push(filters.tenant_id);
    }

    if (filters.status) {
      query += ` AND status = $${args.length + 1}`;
      args.push(filters.status);
    }

    if (filters.batch_reference) {
      query += ` AND batch_reference ILIKE $${args.length + 1}`;
      args.push(`%${filters.batch_reference}%`);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM voucher_batches WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async getByReference(batchReference) {
    const result = await pool.query('SELECT * FROM voucher_batches WHERE batch_reference = $1', [batchReference]);
    return result.rows[0];
  }

  static async create(data) {
    const { tenant_id, batch_reference, voucher_template_id, total_count, created_by } = data;
    const result = await pool.query(
      `INSERT INTO voucher_batches (tenant_id, batch_reference, voucher_template_id, total_count, successful_count, failed_count, status, processing_started_at, created_by) 
       VALUES ($1, $2, $3, $4, 0, 0, 'processing', NOW(), $5) RETURNING *`,
      [tenant_id, batch_reference, voucher_template_id, total_count, created_by]
    );
    return result.rows[0];
  }

  static async updateStatus(id, data) {
    const { successful_count, failed_count, status } = data;
    const result = await pool.query(
      `UPDATE voucher_batches SET successful_count = $1, failed_count = $2, status = $3, processing_completed_at = NOW() WHERE id = $4 RETURNING *`,
      [successful_count, failed_count, status, id]
    );
    return result.rows[0];
  }

  static async delete(id) {
    const result = await pool.query('DELETE FROM voucher_batches WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  }
}

module.exports = VoucherBatch;
