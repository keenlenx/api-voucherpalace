const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class PurchaseOrder {
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM purchase_orders WHERE 1=1';
    const args = [];

    if (filters.consumer_email) {
      query += ` AND consumer_email ILIKE $${args.length + 1}`;
      args.push(`%${filters.consumer_email}%`);
    }

    if (filters.payment_status) {
      query += ` AND payment_status = $${args.length + 1}`;
      args.push(filters.payment_status);
    }

    if (filters.order_type) {
      query += ` AND order_type = $${args.length + 1}`;
      args.push(filters.order_type);
    }

    if (filters.search) {
      query += ` AND (order_number ILIKE $${args.length + 1} OR consumer_email ILIKE $${args.length + 1})`;
      args.push(`%${filters.search}%`);
      args.push(`%${filters.search}%`);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM purchase_orders WHERE id = $1', [id]);
    return result.rows[0];
  }

  static async create(data) {
    const { consumer_id, consumer_email, consumer_phone, voucher_template_id, quantity, unit_price, order_type, gift_recipient_name, gift_recipient_email, gift_message, created_by } = data;
    const orderNumber = `PO-${Date.now()}`;
    const subtotal = quantity * unit_price;
    const totalAmount = subtotal; // Add fee calculation if needed

    const result = await pool.query(
      `INSERT INTO purchase_orders (order_number, consumer_id, consumer_email, consumer_phone, voucher_template_id, quantity, unit_price, subtotal, total_amount, order_type, gift_recipient_name, gift_recipient_email, gift_message, created_by) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING *`,
      [orderNumber, consumer_id, consumer_email, consumer_phone, voucher_template_id, quantity, unit_price, subtotal, totalAmount, order_type, gift_recipient_name, gift_recipient_email, gift_message, created_by]
    );
    return result.rows[0];
  }

  static async updatePaymentStatus(id, paymentStatus) {
    const result = await pool.query(
      `UPDATE purchase_orders SET payment_status = $1, paid_at = CASE WHEN $1 = 'paid' THEN NOW() ELSE paid_at END WHERE id = $2 RETURNING *`,
      [paymentStatus, id]
    );
    return result.rows[0];
  }
}

module.exports = PurchaseOrder;