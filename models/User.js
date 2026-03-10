const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class User {
  static async getAll(filters = {}) {
    try {
      // First check if deleted_at column exists
      const checkColumn = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='users' AND column_name='deleted_at'
      `);
      
      const hasSoftDelete = checkColumn.rows.length > 0;
      
      let query = 'SELECT * FROM users';
      const args = [];
      
      if (hasSoftDelete) {
        query += ' WHERE deleted_at IS NULL';
      } else {
        query += ' WHERE 1=1';
      }

      if (filters.tenant_id) {
        query += ` AND tenant_id = $${args.length + 1}`;
        args.push(filters.tenant_id);
      }

      if (filters.role) {
        query += ` AND role = $${args.length + 1}`;
        args.push(filters.role);
      }

      if (filters.status) {
        query += ` AND status = $${args.length + 1}`;
        args.push(filters.status);
      }

      if (filters.search) {
        query += ` AND (email ILIKE $${args.length + 1} OR first_name ILIKE $${args.length + 1} OR last_name ILIKE $${args.length + 1} OR phone ILIKE $${args.length + 1})`;
        args.push(`%${filters.search}%`);
        args.push(`%${filters.search}%`);
        args.push(`%${filters.search}%`);
        args.push(`%${filters.search}%`);
      }

      query += ' ORDER BY created_at DESC';
      const result = await pool.query(query, args);
      return result.rows;
    } catch (err) {
      console.error('Error in getAll users:', err);
      // Fallback to simple query if complex one fails
      const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
      return result.rows;
    }
  }

  static async getById(id) {
    try {
      const result = await pool.query(
        'SELECT * FROM users WHERE id = $1', 
        [id]
      );
      return result.rows[0];
    } catch (err) {
      console.error('Error in getById:', err);
      return null;
    }
  }

  static async getByEmail(email) {
    try {
      const result = await pool.query(
        'SELECT * FROM users WHERE email = $1', 
        [email]
      );
      return result.rows[0];
    } catch (err) {
      console.error('Error in getByEmail:', err);
      return null;
    }
  }

  static async getByPhone(phone) {
    try {
      const result = await pool.query(
        'SELECT * FROM users WHERE phone = $1', 
        [phone]
      );
      return result.rows[0];
    } catch (err) {
      console.error('Error in getByPhone:', err);
      return null;
    }
  }

  static async getByIdentifier(identifier) {
    const isEmail = identifier.includes('@');
    if (isEmail) {
      return await this.getByEmail(identifier);
    } else {
      return await this.getByPhone(identifier);
    }
  }

  static async getByRefreshToken(refreshToken) {
    try {
      // Check if column exists first
      const checkColumn = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='users' AND column_name='refresh_token'
      `);
      
      if (checkColumn.rows.length === 0) {
        return null;
      }
      
      const result = await pool.query(
        'SELECT * FROM users WHERE refresh_token = $1', 
        [refreshToken]
      );
      return result.rows[0];
    } catch (err) {
      console.error('Error in getByRefreshToken:', err);
      return null;
    }
  }

  static async getByResetToken(token) {
    try {
      // Check if column exists
      const checkColumn = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='users' AND column_name='password_reset_token'
      `);
      
      if (checkColumn.rows.length === 0) {
        return null;
      }
      
      const result = await pool.query(
        'SELECT * FROM users WHERE password_reset_token = $1', 
        [token]
      );
      return result.rows[0];
    } catch (err) {
      console.error('Error in getByResetToken:', err);
      return null;
    }
  }

  static async create(data) {
    const { 
      tenant_id, 
      email, 
      password_hash, 
      first_name, 
      last_name, 
      phone, 
      role = 'client_user', 
      created_by 
    } = data;
    
    const result = await pool.query(
      `INSERT INTO users (
        tenant_id, email, password_hash, first_name, last_name, 
        phone, role, created_by, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'active') 
      RETURNING *`,
      [tenant_id, email, password_hash, first_name, last_name, phone, role, created_by]
    );
    return result.rows[0];
  }

  static async update(id, data) {
    const { 
      email, 
      first_name, 
      last_name, 
      phone, 
      status, 
      role,
      last_login_at,
      refresh_token,
      password_reset_token,
      password_reset_expires,
      password_hash,
      updated_by 
    } = data;

    // Build dynamic update query based on provided fields
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (email !== undefined) {
      updates.push(`email = $${paramCount++}`);
      values.push(email);
    }
    if (first_name !== undefined) {
      updates.push(`first_name = $${paramCount++}`);
      values.push(first_name);
    }
    if (last_name !== undefined) {
      updates.push(`last_name = $${paramCount++}`);
      values.push(last_name);
    }
    if (phone !== undefined) {
      updates.push(`phone = $${paramCount++}`);
      values.push(phone);
    }
    if (status !== undefined) {
      updates.push(`status = $${paramCount++}`);
      values.push(status);
    }
    if (role !== undefined) {
      updates.push(`role = $${paramCount++}`);
      values.push(role);
    }
    if (last_login_at !== undefined) {
      updates.push(`last_login_at = $${paramCount++}`);
      values.push(last_login_at);
    }
    if (refresh_token !== undefined) {
      updates.push(`refresh_token = $${paramCount++}`);
      values.push(refresh_token);
    }
    if (password_reset_token !== undefined) {
      updates.push(`password_reset_token = $${paramCount++}`);
      values.push(password_reset_token);
    }
    if (password_reset_expires !== undefined) {
      updates.push(`password_reset_expires = $${paramCount++}`);
      values.push(password_reset_expires);
    }
    if (password_hash !== undefined) {
      updates.push(`password_hash = $${paramCount++}`);
      values.push(password_hash);
    }
    if (updated_by !== undefined) {
      updates.push(`updated_by = $${paramCount++}`);
      values.push(updated_by);
    }

    updates.push(`updated_at = NOW()`);

    if (updates.length === 0) {
      return await this.getById(id);
    }

    values.push(id);
    
    const query = `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`;
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (err) {
      console.error('Error in update:', err);
      return null;
    }
  }

  static async softDelete(id, deleted_by) {
    try {
      // Check if columns exist
      const checkColumns = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='users' AND column_name IN ('deleted_at', 'deleted_by')
      `);
      
      const hasColumns = checkColumns.rows.length >= 2;
      
      if (!hasColumns) {
        // If columns don't exist, just update status
        const result = await pool.query(
          `UPDATE users SET 
            status = 'suspended',
            updated_at = NOW()
          WHERE id = $1 
          RETURNING *`,
          [id]
        );
        return result.rows[0];
      }
      
      const result = await pool.query(
        `UPDATE users SET 
          deleted_at = NOW(), 
          deleted_by = $1,
          status = 'suspended',
          refresh_token = NULL,
          password_reset_token = NULL,
          password_reset_expires = NULL
        WHERE id = $2 
        RETURNING *`,
        [deleted_by, id]
      );
      return result.rows[0];
    } catch (err) {
      console.error('Error in softDelete:', err);
      // Fallback to simple status update
      const result = await pool.query(
        `UPDATE users SET status = 'suspended' WHERE id = $1 RETURNING *`,
        [id]
      );
      return result.rows[0];
    }
  }

  static async restore(id) {
    try {
      // Check if deleted_at column exists
      const checkColumn = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='users' AND column_name='deleted_at'
      `);
      
      if (checkColumn.rows.length === 0) {
        const result = await pool.query(
          `UPDATE users SET status = 'active' WHERE id = $1 RETURNING *`,
          [id]
        );
        return result.rows[0];
      }
      
      const result = await pool.query(
        `UPDATE users SET 
          deleted_at = NULL, 
          deleted_by = NULL,
          status = 'active'
        WHERE id = $1 
        RETURNING *`,
        [id]
      );
      return result.rows[0];
    } catch (err) {
      console.error('Error in restore:', err);
      // Fallback to simple status update
      const result = await pool.query(
        `UPDATE users SET status = 'active' WHERE id = $1 RETURNING *`,
        [id]
      );
      return result.rows[0];
    }
  }
}

module.exports = User;