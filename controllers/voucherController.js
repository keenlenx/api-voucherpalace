const Voucher = require('../models/Voucher');
const VoucherBatch = require('../models/VoucherBatch');
const VoucherTemplate = require('../models/VoucherTemplate');
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// ===== EXISTING METHODS =====

exports.getAllVouchers = async (req, res) => {
  try {
    const filters = {
      tenant_id: req.query.tenant_id,
      status: req.query.status,
      voucher_template_id: req.query.voucher_template_id,
      code: req.query.code,
      search: req.query.search,
    };
    const vouchers = await Voucher.getAll(filters);
    res.json({ 
      success: true, 
      data: vouchers, 
      count: vouchers.length 
    });
  } catch (err) {
    console.error('Get all vouchers error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

exports.getVoucherById = async (req, res) => {
  try {
    const voucher = await Voucher.getById(req.params.id);
    if (!voucher) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher not found' 
      });
    }
    res.json({ 
      success: true, 
      data: voucher 
    });
  } catch (err) {
    console.error('Get voucher by id error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

exports.getVoucherByCode = async (req, res) => {
  try {
    const voucher = await Voucher.getByCode(req.params.code);
    if (!voucher) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher not found' 
      });
    }
    res.json({ 
      success: true, 
      data: voucher 
    });
  } catch (err) {
    console.error('Get voucher by code error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

exports.createVoucher = async (req, res) => {
  try {
    const voucher = await Voucher.create({ 
      ...req.body, 
      created_by: req.user?.id 
    });
    res.status(201).json({ 
      success: true, 
      data: voucher 
    });
  } catch (err) {
    console.error('Create voucher error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

exports.updateVoucher = async (req, res) => {
  try {
    const voucher = await Voucher.update(req.params.id, { 
      ...req.body, 
      updated_by: req.user?.id 
    });
    if (!voucher) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher not found' 
      });
    }
    res.json({ 
      success: true, 
      data: voucher 
    });
  } catch (err) {
    console.error('Update voucher error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

exports.deleteVoucher = async (req, res) => {
  try {
    const voucher = await Voucher.delete(req.params.id);
    if (!voucher) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher not found' 
      });
    }
    res.status(204).send();
  } catch (err) {
    console.error('Delete voucher error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

// ===== BULK OPERATIONS =====

exports.bulkCreateVouchers = async (req, res) => {
  const { template_id, staff_list } = req.body;
  const userId = req.user?.id;
  const tenantId = req.user?.tenant_id;

  try {
    // Validation
    if (!template_id || !staff_list) {
      return res.status(400).json({ 
        success: false, 
        error: 'template_id and staff_list are required' 
      });
    }

    if (!Array.isArray(staff_list) || staff_list.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'staff_list must be a non-empty array' 
      });
    }

    // Get template
    const template = await VoucherTemplate.getById(template_id);
    if (!template || !template.is_active) {
      return res.status(404).json({ 
        success: false, 
        error: 'Template not found or inactive' 
      });
    }

    // Create batch record
    const batchReference = `BATCH-${Date.now()}-${Math.random().toString(16).substr(2, 8)}`;
    const batch = await VoucherBatch.create({
      tenant_id: tenantId,
      batch_reference: batchReference,
      voucher_template_id: template_id,
      total_count: staff_list.length,
      created_by: userId,
    });

    // Prepare voucher data for bulk creation
    const vouchersData = staff_list.map((staff, index) => {
      if (!staff.name) {
        throw new Error(`Staff name is required at index ${index}`);
      }
      
      return {
        voucher_template_id: template_id,
        tenant_id: tenantId,
        original_value: parseFloat(template.value_amount),
        beneficiary_name: staff.name,
        beneficiary_email: staff.email || null,
        beneficiary_phone: staff.phone || null,
        expires_at: staff.expiry_date || template.valid_to,
        created_by: userId,
      };
    });

    // Use the bulk create method from model
    const result = await Voucher.createBulk(vouchersData);

    // Update batch status
    await VoucherBatch.updateStatus(batch.id, {
      successful_count: result.vouchers.length,
      failed_count: 0,
      status: 'completed',
    });

    res.status(200).json({
      success: true,
      data: {
        batch_id: batchReference,
        batch_record_id: batch.id,
        template_name: template.template_name,
        total: staff_list.length,
        created: result.vouchers.length,
        vouchers: result.vouchers.map(v => ({
          id: v.id,
          code: v.code,
          beneficiary_name: v.beneficiary_name
        })),
        batch_status: 'completed',
      },
      message: `${result.vouchers.length} vouchers created successfully`,
    });

  } catch (err) {
    console.error('Bulk creation error:', err);
    res.status(500).json({ 
      success: false, 
      error: 'Bulk creation failed', 
      message: err.message 
    });
  }
};

// ===== BATCH STATUS =====

exports.getBatchStatus = async (req, res) => {
  try {
    const { batch_id } = req.params;
    const tenantId = req.user?.tenant_id;

    // Support both batch_record_id and batch_reference
    let batch = await VoucherBatch.getById(batch_id);
    if (!batch) {
      batch = await VoucherBatch.getByReference(batch_id);
    }

    if (!batch || batch.tenant_id !== tenantId) {
      return res.status(404).json({ 
        success: false, 
        error: 'Batch not found' 
      });
    }

    // Get all vouchers in this batch
    const vouchers = await pool.query(
      `SELECT id, code, status, beneficiary_name, created_at 
       FROM vouchers 
       WHERE batch_id = $1 
       ORDER BY created_at DESC`,
      [batch.id]
    );

    res.status(200).json({
      success: true,
      data: {
        ...batch,
        vouchers: vouchers.rows,
      },
    });
  } catch (err) {
    console.error('Get batch error:', err);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to get batch', 
      message: err.message 
    });
  }
};

// ===== NEW METHODS FROM ENHANCED MODEL =====

/**
 * Get voucher statistics
 */
exports.getVoucherStats = async (req, res) => {
  try {
    const { tenant_id } = req.query;
    const days = parseInt(req.query.days) || 30;
    
    if (!tenant_id) {
      return res.status(400).json({ 
        success: false, 
        error: 'tenant_id is required' 
      });
    }

    const stats = await Voucher.getStats(tenant_id, days);
    
    res.json({
      success: true,
      data: stats
    });
  } catch (err) {
    console.error('Get voucher stats error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Mark expired vouchers
 */
exports.markExpiredVouchers = async (req, res) => {
  try {
    const expired = await Voucher.markExpired();
    
    res.json({
      success: true,
      data: {
        count: expired.length,
        vouchers: expired
      },
      message: `${expired.length} vouchers marked as expired`
    });
  } catch (err) {
    console.error('Mark expired vouchers error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Get vouchers expiring soon
 */
exports.getExpiringSoon = async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 7;
    const { tenant_id } = req.query;
    
    const expiring = await Voucher.getExpiringSoon(days, tenant_id);
    
    res.json({
      success: true,
      data: expiring,
      count: expiring.length
    });
  } catch (err) {
    console.error('Get expiring soon error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Redeem a voucher
 */
exports.redeemVoucher = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, metadata = {} } = req.body;
    const redeemedBy = req.user?.id;

    if (!amount) {
      return res.status(400).json({ 
        success: false, 
        error: 'Redemption amount is required' 
      });
    }

    const result = await Voucher.redeem(id, parseFloat(amount), redeemedBy, metadata);
    
    res.json({
      success: true,
      data: result,
      message: 'Voucher redeemed successfully'
    });
  } catch (err) {
    console.error('Redeem voucher error:', err);
    
    // Handle specific error messages
    if (err.message.includes('not found')) {
      return res.status(404).json({ 
        success: false, 
        error: err.message 
      });
    }
    if (err.message.includes('not active') || err.message.includes('Insufficient')) {
      return res.status(400).json({ 
        success: false, 
        error: err.message 
      });
    }
    
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Get redemption history for a voucher
 */
exports.getVoucherRedemptionHistory = async (req, res) => {
  try {
    const { id } = req.params;
    
    // First check if voucher exists
    const voucher = await Voucher.getById(id);
    if (!voucher) {
      return res.status(404).json({ 
        success: false, 
        error: 'Voucher not found' 
      });
    }

    const history = await Voucher.getRedemptionHistory(id);
    
    res.json({
      success: true,
      data: history,
      count: history.length
    });
  } catch (err) {
    console.error('Get redemption history error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Advanced search with multiple filters
 */
exports.advancedSearch = async (req, res) => {
  try {
    const filters = {
      tenant_id: req.query.tenant_id,
      date_from: req.query.date_from,
      date_to: req.query.date_to,
      min_value: req.query.min_value ? parseFloat(req.query.min_value) : undefined,
      max_value: req.query.max_value ? parseFloat(req.query.max_value) : undefined,
      beneficiary: req.query.beneficiary,
      template_id: req.query.template_id,
      has_redemptions: req.query.has_redemptions === 'true' ? true : 
                       req.query.has_redemptions === 'false' ? false : undefined
    };

    const vouchers = await Voucher.searchAdvanced(filters);
    
    res.json({
      success: true,
      data: vouchers,
      count: vouchers.length
    });
  } catch (err) {
    console.error('Advanced search error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Export vouchers for date range
 */
exports.exportVouchers = async (req, res) => {
  try {
    const { tenant_id, start_date, end_date } = req.query;
    
    if (!tenant_id || !start_date || !end_date) {
      return res.status(400).json({ 
        success: false, 
        error: 'tenant_id, start_date, and end_date are required' 
      });
    }

    const vouchers = await Voucher.exportForDateRange(tenant_id, start_date, end_date);
    
    res.json({
      success: true,
      data: vouchers,
      count: vouchers.length
    });
  } catch (err) {
    console.error('Export vouchers error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Get performance by template
 */
exports.getTemplatePerformance = async (req, res) => {
  try {
    const { tenant_id } = req.query;
    const days = parseInt(req.query.days) || 30;
    
    if (!tenant_id) {
      return res.status(400).json({ 
        success: false, 
        error: 'tenant_id is required' 
      });
    }

    const performance = await Voucher.getPerformanceByTemplate(tenant_id, days);
    
    res.json({
      success: true,
      data: performance
    });
  } catch (err) {
    console.error('Get template performance error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Bulk update voucher status
 */
exports.bulkUpdateStatus = async (req, res) => {
  try {
    const { ids, status } = req.body;
    const updatedBy = req.user?.id;

    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Voucher IDs array is required' 
      });
    }

    if (!status) {
      return res.status(400).json({ 
        success: false, 
        error: 'Status is required' 
      });
    }

    const updated = await Voucher.bulkUpdateStatus(ids, status, updatedBy);
    
    res.json({
      success: true,
      data: updated,
      count: updated.length,
      message: `${updated.length} vouchers updated successfully`
    });
  } catch (err) {
    console.error('Bulk update error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Find potential duplicate vouchers
 */
exports.findPotentialDuplicates = async (req, res) => {
  try {
    const { email } = req.query;
    const days = parseInt(req.query.days) || 7;

    if (!email) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email is required' 
      });
    }

    const duplicates = await Voucher.findPotentialDuplicates(email, days);
    
    res.json({
      success: true,
      data: duplicates,
      count: duplicates.length
    });
  } catch (err) {
    console.error('Find duplicates error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Transfer beneficiary
 */
exports.transferBeneficiary = async (req, res) => {
  try {
    const { old_email, new_email } = req.body;

    if (!old_email || !new_email) {
      return res.status(400).json({ 
        success: false, 
        error: 'old_email and new_email are required' 
      });
    }

    const transferred = await Voucher.transferBeneficiary(old_email, new_email);
    
    res.json({
      success: true,
      data: transferred,
      count: transferred.length,
      message: `${transferred.length} vouchers transferred successfully`
    });
  } catch (err) {
    console.error('Transfer beneficiary error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};

/**
 * Clean up old records
 */
exports.cleanupOldRecords = async (req, res) => {
  try {
    const daysOld = parseInt(req.query.days) || 365;
    
    const deletedCount = await Voucher.cleanupOldRecords(daysOld);
    
    res.json({
      success: true,
      data: { deleted: deletedCount },
      message: `${deletedCount} old records cleaned up`
    });
  } catch (err) {
    console.error('Cleanup error:', err);
    res.status(500).json({ 
      success: false, 
      error: err.message 
    });
  }
};