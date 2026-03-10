const VoucherTemplate = require('../models/VoucherTemplate');

// ===== GET ALL TEMPLATES WITH FILTERS =====
exports.getAllVoucherTemplates = async (req, res) => {
  try {
    const filters = {};
    
    // Extract query parameters
    if (req.query.tenant_id) filters.tenant_id = req.query.tenant_id;
    if (req.query.voucher_type) filters.voucher_type = req.query.voucher_type;
    if (req.query.is_active !== undefined) filters.is_active = req.query.is_active === 'true';
    if (req.query.is_public_visible !== undefined) filters.is_public_visible = req.query.is_public_visible === 'true';
    if (req.query.search) filters.search = req.query.search;
    
    console.log('📋 Fetching templates with filters:', filters);
    
    const templates = await VoucherTemplate.getAll(filters);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error fetching templates:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET TEMPLATE BY ID =====
exports.getVoucherTemplateById = async (req, res) => {
  try {
    const template = await VoucherTemplate.getById(req.params.id);
    
    if (!template) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher template not found' 
      });
    }
    
    res.json({
      success: true,
      data: template
    });
  } catch (err) {
    console.error('❌ Error fetching template by ID:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET TEMPLATES BY TENANT ID =====
exports.getVoucherTemplatesByTenantId = async (req, res) => {
  try {
    const { tenantId } = req.params;
    const includeInactive = req.query.include_inactive === 'true';
    
    console.log(`📋 Fetching templates for tenant: ${tenantId} (includeInactive: ${includeInactive})`);
    
    const templates = await VoucherTemplate.getByTenantId(tenantId, includeInactive);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error fetching templates by tenant:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET TEMPLATES BY MERCHANT ID =====
exports.getVoucherTemplatesByMerchantId = async (req, res) => {
  try {
    const { merchantId } = req.params;
    
    console.log(`📋 Fetching templates for merchant: ${merchantId}`);
    
    const templates = await VoucherTemplate.getByMerchantId(merchantId);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error fetching templates by merchant:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET PUBLIC TEMPLATES =====
exports.getPublicVoucherTemplates = async (req, res) => {
  try {
    const { tenantId } = req.query;
    
    console.log(`📋 Fetching public templates${tenantId ? ` for tenant: ${tenantId}` : ''}`);
    
    const templates = await VoucherTemplate.getPublicTemplates(tenantId);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error fetching public templates:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET ACTIVE TEMPLATES (with valid dates) =====
exports.getActiveVoucherTemplates = async (req, res) => {
  try {
    const { tenantId } = req.query;
    
    console.log(`📋 Fetching active templates${tenantId ? ` for tenant: ${tenantId}` : ''}`);
    
    const templates = await VoucherTemplate.getActiveTemplates(tenantId);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error fetching active templates:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET TEMPLATES BY TYPE =====
exports.getVoucherTemplatesByType = async (req, res) => {
  try {
    const { type } = req.params;
    const { tenantId } = req.query;
    
    console.log(`📋 Fetching ${type} templates${tenantId ? ` for tenant: ${tenantId}` : ''}`);
    
    const templates = await VoucherTemplate.getByType(type, tenantId);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error fetching templates by type:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET EXPIRING TEMPLATES =====
exports.getExpiringVoucherTemplates = async (req, res) => {
  try {
    const daysThreshold = parseInt(req.query.days) || 30;
    const { tenantId } = req.query;
    
    console.log(`📋 Fetching templates expiring within ${daysThreshold} days`);
    
    const templates = await VoucherTemplate.getExpiringTemplates(daysThreshold, tenantId);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error fetching expiring templates:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== GET TEMPLATE USAGE STATISTICS =====
exports.getVoucherTemplateStats = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`📊 Fetching usage stats for template: ${id}`);
    
    const stats = await VoucherTemplate.getUsageStats(id);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (err) {
    console.error('❌ Error fetching template stats:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== COUNT TEMPLATES BY TENANT =====
exports.countVoucherTemplatesByTenant = async (req, res) => {
  try {
    const { tenantId } = req.params;
    
    console.log(`🔢 Counting templates for tenant: ${tenantId}`);
    
    const count = await VoucherTemplate.countByTenant(tenantId);
    
    res.json({
      success: true,
      count
    });
  } catch (err) {
    console.error('❌ Error counting templates:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== CREATE TEMPLATE =====
exports.createVoucherTemplate = async (req, res) => {
  try {
    console.log('📝 Creating new voucher template:', req.body);
    
    const template = await VoucherTemplate.create(req.body);
    
    res.status(201).json({
      success: true,
      data: template
    });
  } catch (err) {
    console.error('❌ Error creating template:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== UPDATE TEMPLATE =====
exports.updateVoucherTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`📝 Updating voucher template: ${id}`);
    
    const template = await VoucherTemplate.update(id, req.body);
    
    if (!template) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher template not found' 
      });
    }
    
    res.json({
      success: true,
      data: template
    });
  } catch (err) {
    console.error('❌ Error updating template:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== DELETE TEMPLATE (HARD DELETE) =====
exports.deleteVoucherTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🗑️ Hard deleting voucher template: ${id}`);
    
    const template = await VoucherTemplate.delete(id);
    
    if (!template) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher template not found' 
      });
    }
    
    res.status(204).send();
  } catch (err) {
    console.error('❌ Error deleting template:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== SOFT DELETE (DEACTIVATE) =====
exports.deactivateVoucherTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const { updated_by } = req.body;
    
    console.log(`🔽 Soft deleting (deactivating) template: ${id}`);
    
    const template = await VoucherTemplate.softDelete(id, updated_by);
    
    if (!template) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher template not found' 
      });
    }
    
    res.json({
      success: true,
      data: template,
      message: 'Template deactivated successfully'
    });
  } catch (err) {
    console.error('❌ Error deactivating template:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== BULK UPDATE TEMPLATES =====
exports.bulkUpdateVoucherTemplates = async (req, res) => {
  try {
    const { ids, updates } = req.body;
    
    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Template IDs array is required' 
      });
    }
    
    console.log(`📦 Bulk updating ${ids.length} templates`);
    
    const templates = await VoucherTemplate.bulkUpdate(ids, updates);
    
    res.json({
      success: true,
      data: templates,
      count: templates.length
    });
  } catch (err) {
    console.error('❌ Error bulk updating templates:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== DUPLICATE TEMPLATE =====
exports.duplicateVoucherTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const { new_name, created_by } = req.body;
    
    console.log(`📋 Duplicating template: ${id}`);
    
    const template = await VoucherTemplate.duplicate(id, new_name, created_by);
    
    if (!template) {
      return res.status(404).json({ 
        success: false, 
        error: 'Original template not found' 
      });
    }
    
    res.status(201).json({
      success: true,
      data: template,
      message: 'Template duplicated successfully'
    });
  } catch (err) {
    console.error('❌ Error duplicating template:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};