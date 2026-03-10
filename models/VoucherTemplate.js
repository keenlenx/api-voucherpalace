const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

class VoucherTemplate {
  // ===== EXISTING METHODS =====
  
  static async getAll(filters = {}) {
    let query = 'SELECT * FROM voucher_templates WHERE 1=1';
    const args = [];

    if (filters.tenant_id) {
      query += ` AND tenant_id = $${args.length + 1}`;
      args.push(filters.tenant_id);
    }

    if (filters.voucher_type) {
      query += ` AND voucher_type = $${args.length + 1}`;
      args.push(filters.voucher_type);
    }

    if (filters.is_active !== undefined) {
      query += ` AND is_active = $${args.length + 1}`;
      args.push(filters.is_active);
    }

    if (filters.is_public_visible !== undefined) {
      query += ` AND is_public_visible = $${args.length + 1}`;
      args.push(filters.is_public_visible);
    }

    if (filters.search) {
      query += ` AND (template_name ILIKE $${args.length + 1} OR description ILIKE $${args.length + 1})`;
      args.push(`%${filters.search}%`);
    }

    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, args);
    return result.rows;
  }

  static async getById(id) {
    const result = await pool.query('SELECT * FROM voucher_templates WHERE id = $1', [id]);
    return result.rows[0];
  }

  // ===== NEW METHOD: Get templates by tenant ID =====
  static async getByTenantId(tenantId, includeInactive = false) {
    console.log(`📋 VoucherTemplate.getByTenantId called for tenant: ${tenantId}`);
    
    let query = 'SELECT * FROM voucher_templates WHERE tenant_id = $1';
    const args = [tenantId];
    
    if (!includeInactive) {
      query += ' AND is_active = true';
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, args);
    return result.rows;
  }

  // ===== NEW METHOD: Get public templates (visible in storefront) =====
  static async getPublicTemplates(tenantId = null) {
    let query = 'SELECT * FROM voucher_templates WHERE is_public_visible = true AND is_active = true';
    const args = [];
    
    if (tenantId) {
      query += ` AND tenant_id = $${args.length + 1}`;
      args.push(tenantId);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, args);
    return result.rows;
  }

  // ===== NEW METHOD: Get templates by merchant ID (via tenant relationship) =====
  static async getByMerchantId(merchantId) {
    // First get the merchant's tenant_id
    const merchantResult = await pool.query(
      'SELECT tenant_id FROM merchants WHERE id = $1',
      [merchantId]
    );
    
    if (merchantResult.rows.length === 0) {
      return [];
    }
    
    const tenantId = merchantResult.rows[0].tenant_id;
    
    // Then get templates for that tenant
    return this.getByTenantId(tenantId);
  }

  // ===== NEW METHOD: Get active templates with valid dates =====
  static async getActiveTemplates(tenantId = null) {
    let query = 'SELECT * FROM voucher_templates WHERE is_active = true';
    const args = [];
    let paramCount = 0;
    
    if (tenantId) {
      paramCount++;
      query += ` AND tenant_id = $${paramCount}`;
      args.push(tenantId);
    }
    
    // Check if current date is within valid range
    const now = new Date().toISOString();
    paramCount++;
    query += ` AND (valid_from IS NULL OR valid_from <= $${paramCount})`;
    args.push(now);
    
    paramCount++;
    query += ` AND (valid_to IS NULL OR valid_to >= $${paramCount})`;
    args.push(now);
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, args);
    return result.rows;
  }

  // ===== NEW METHOD: Get templates by type =====
  static async getByType(voucherType, tenantId = null) {
    let query = 'SELECT * FROM voucher_templates WHERE voucher_type = $1 AND is_active = true';
    const args = [voucherType];
    
    if (tenantId) {
      query += ` AND tenant_id = $${args.length + 1}`;
      args.push(tenantId);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, args);
    return result.rows;
  }

  // ===== NEW METHOD: Count templates by tenant =====
  static async countByTenant(tenantId) {
    const result = await pool.query(
      'SELECT COUNT(*) FROM voucher_templates WHERE tenant_id = $1',
      [tenantId]
    );
    return parseInt(result.rows[0].count);
  }

  // ===== NEW METHOD: Get expiring templates =====
  static async getExpiringTemplates(daysThreshold = 30, tenantId = null) {
    const thresholdDate = new Date();
    thresholdDate.setDate(thresholdDate.getDate() + daysThreshold);
    
    let query = 'SELECT * FROM voucher_templates WHERE valid_to IS NOT NULL AND valid_to <= $1 AND is_active = true';
    const args = [thresholdDate.toISOString()];
    
    if (tenantId) {
      query += ` AND tenant_id = $${args.length + 1}`;
      args.push(tenantId);
    }
    
    query += ' ORDER BY valid_to ASC';
    
    const result = await pool.query(query, args);
    return result.rows;
  }

  // ===== NEW METHOD: Bulk update templates =====
  static async bulkUpdate(ids, updates) {
    const { is_active, is_public_visible } = updates;
    
    if (!ids || ids.length === 0) return [];
    
    const placeholders = ids.map((_, i) => `$${i + 1}`).join(',');
    let query = 'UPDATE voucher_templates SET updated_at = NOW()';
    const values = [...ids];
    
    if (is_active !== undefined) {
      query += `, is_active = $${values.length + 1}`;
      values.push(is_active);
    }
    
    if (is_public_visible !== undefined) {
      query += `, is_public_visible = $${values.length + 1}`;
      values.push(is_public_visible);
    }
    
    query += ` WHERE id IN (${placeholders}) RETURNING *`;
    
    const result = await pool.query(query, values);
    return result.rows;
  }

  // ===== NEW METHOD: Duplicate template =====
  static async duplicate(id, newName, createdBy) {
    // Get original template
    const original = await this.getById(id);
    if (!original) return null;
    
    // Create copy with new name
    const { tenant_id, template_name, description, voucher_type, value_amount, 
            percentage_value, valid_from, valid_to, usage_limit_type, 
            usage_limit_count, min_purchase_amount, is_public_visible, 
            public_price, public_image_url } = original;
    
    const result = await pool.query(
      `INSERT INTO voucher_templates (
        tenant_id, template_name, description, voucher_type, value_amount, 
        percentage_value, valid_from, valid_to, usage_limit_type, 
        usage_limit_count, min_purchase_amount, is_public_visible, 
        public_price, public_image_url, created_by, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16) RETURNING *`,
      [tenant_id, newName || `${template_name} (Copy)`, description, voucher_type, 
       value_amount, percentage_value, valid_from, valid_to, usage_limit_type, 
       usage_limit_count, min_purchase_amount, is_public_visible, 
       public_price, public_image_url, createdBy, true]
    );
    
    return result.rows[0];
  }

  // ===== EXISTING CRUD METHODS =====
  
  static async create(data) {
    const { 
      tenant_id, template_name, description, voucher_type, 
      value_amount, percentage_value, valid_from, valid_to, 
      usage_limit_type, usage_limit_count, min_purchase_amount, 
      is_public_visible, public_price, public_image_url, created_by,
      background_color = '#FFFFFF', text_color = '#000000',
      terms_and_conditions, metadata = {}
    } = data;
    
    const result = await pool.query(
      `INSERT INTO voucher_templates (
        tenant_id, template_name, description, voucher_type, 
        value_amount, percentage_value, valid_from, valid_to, 
        usage_limit_type, usage_limit_count, min_purchase_amount, 
        is_public_visible, public_price, public_image_url, 
        background_color, text_color, terms_and_conditions, metadata, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19) RETURNING *`,
      [tenant_id, template_name, description, voucher_type, 
       value_amount, percentage_value, valid_from, valid_to, 
       usage_limit_type || 'single', usage_limit_count, 
       min_purchase_amount || 0, is_public_visible || false, 
       public_price, public_image_url, background_color, text_color,
       terms_and_conditions, metadata, created_by]
    );
    return result.rows[0];
  }

  static async update(id, data) {
    const { 
      template_name, description, value_amount, percentage_value, 
      valid_from, valid_to, usage_limit_type, usage_limit_count, 
      min_purchase_amount, is_active, is_public_visible, public_price,
      public_image_url, background_color, text_color, terms_and_conditions,
      metadata, updated_by
    } = data;
    
    const result = await pool.query(
      `UPDATE voucher_templates SET 
        template_name = COALESCE($1, template_name),
        description = COALESCE($2, description),
        value_amount = COALESCE($3, value_amount),
        percentage_value = COALESCE($4, percentage_value),
        valid_from = COALESCE($5, valid_from),
        valid_to = COALESCE($6, valid_to),
        usage_limit_type = COALESCE($7, usage_limit_type),
        usage_limit_count = COALESCE($8, usage_limit_count),
        min_purchase_amount = COALESCE($9, min_purchase_amount),
        is_active = COALESCE($10, is_active),
        is_public_visible = COALESCE($11, is_public_visible),
        public_price = COALESCE($12, public_price),
        public_image_url = COALESCE($13, public_image_url),
        background_color = COALESCE($14, background_color),
        text_color = COALESCE($15, text_color),
        terms_and_conditions = COALESCE($16, terms_and_conditions),
        metadata = COALESCE($17, metadata),
        updated_by = $18,
        updated_at = NOW()
      WHERE id = $19 RETURNING *`,
      [template_name, description, value_amount, percentage_value, 
       valid_from, valid_to, usage_limit_type, usage_limit_count, 
       min_purchase_amount, is_active, is_public_visible, public_price,
       public_image_url, background_color, text_color, terms_and_conditions,
       metadata, updated_by, id]
    );
    return result.rows[0];
  }

  static async delete(id) {
    const result = await pool.query('DELETE FROM voucher_templates WHERE id = $1 RETURNING *', [id]);
    return result.rows[0];
  }

  // ===== NEW METHOD: Soft delete (deactivate) =====
  static async softDelete(id, updatedBy) {
    const result = await pool.query(
      'UPDATE voucher_templates SET is_active = false, updated_by = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [updatedBy, id]
    );
    return result.rows[0];
  }

  // ===== NEW METHOD: Get template usage statistics =====
  static async getUsageStats(templateId) {
    const result = await pool.query(
      `SELECT 
        COUNT(*) as total_issued,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active_count,
        COUNT(CASE WHEN status = 'redeemed' THEN 1 END) as redeemed_count,
        COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired_count,
        SUM(original_value) as total_value,
        SUM(remaining_value) as remaining_value
      FROM vouchers 
      WHERE voucher_template_id = $1`,
      [templateId]
    );
    return result.rows[0];
  }
}

module.exports = VoucherTemplate;