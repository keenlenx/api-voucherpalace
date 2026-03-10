const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class Tenant {
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM tenants WHERE 1=1';
    const args = [];

    if (filters.status) {
      query += ` AND status = $${args.length + 1}`;
      args.push(filters.status);
    }

    if (filters.tenant_type) {
      query += ` AND tenant_type = $${args.length + 1}`;
      args.push(filters.tenant_type);
    }

    if (filters.search) {
      query += ` AND (tenant_name ILIKE $${args.length + 1} OR email ILIKE $${args.length + 1})`;
      args.push(`%${filters.search}%`);
      args.push(`%${filters.search}%`);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM tenants WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async create(data) {
    const { tenant_name, tenant_type, registration_number, tax_id, email, phone, address, website, logo_url, billing_cycle, settings, created_by } = data;
    const result = await pool.query(
      `INSERT INTO tenants (tenant_name, tenant_type, registration_number, tax_id, email, phone, address, website, logo_url, billing_cycle, settings, created_by) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
      [tenant_name, tenant_type, registration_number, tax_id, email, phone, address, website, logo_url, billing_cycle || 'monthly', settings || {}, created_by]
    );
    return result.rows[0];
  }

  static async update(id, data) {
    const { tenant_name, tenant_type, email, phone, address, status, wallet_balance, credit_limit, updated_by } = data;
    const result = await pool.query(
      `UPDATE tenants SET tenant_name = COALESCE($1, tenant_name), tenant_type = COALESCE($2, tenant_type), email = COALESCE($3, email), 
       phone = COALESCE($4, phone), address = COALESCE($5, address), status = COALESCE($6, status), wallet_balance = COALESCE($7, wallet_balance), 
       credit_limit = COALESCE($8, credit_limit), updated_by = $9 WHERE id = $10 RETURNING *`,
      [tenant_name, tenant_type, email, phone, address, status, wallet_balance, credit_limit, updated_by, id]
    );
    return result.rows[0];
  }

  static async delete(id) {
    const result = await pool.query('DELETE FROM tenants WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  }
}

module.exports = Tenant;