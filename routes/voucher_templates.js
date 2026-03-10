const express = require('express');
const router = express.Router();
const voucherTemplateController = require('../controllers/voucherTemplateController');

/**
 * @swagger
 * tags:
 *   - name: Voucher Templates
 *     description: Voucher template creation and management
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     VoucherTemplate:
 *       type: object
 *       required:
 *         - tenant_id
 *         - template_name
 *         - voucher_type
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         tenant_id:
 *           type: string
 *           format: uuid
 *         template_name:
 *           type: string
 *         description:
 *           type: string
 *         voucher_type:
 *           type: string
 *           enum: [fixed_amount, percentage, open_cash]
 *         value_amount:
 *           type: number
 *         percentage_value:
 *           type: number
 *         valid_from:
 *           type: string
 *           format: date-time
 *         valid_to:
 *           type: string
 *           format: date-time
 *         usage_limit_type:
 *           type: string
 *           enum: [single, multi, unlimited]
 *         usage_limit_count:
 *           type: integer
 *         min_purchase_amount:
 *           type: number
 *         is_active:
 *           type: boolean
 *         is_public_visible:
 *           type: boolean
 *         public_price:
 *           type: number
 *         public_image_url:
 *           type: string
 *         background_color:
 *           type: string
 *         text_color:
 *           type: string
 *         terms_and_conditions:
 *           type: string
 *         metadata:
 *           type: object
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 */

// ===== BASE ROUTES =====

/**
 * @swagger
 * /voucher_templates:
 *   get:
 *     summary: Get all voucher templates with optional filters
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: query
 *         name: tenant_id
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: voucher_type
 *         schema:
 *           type: string
 *           enum: [fixed_amount, percentage, open_cash]
 *       - in: query
 *         name: is_active
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: is_public_visible
 *         schema:
 *           type: boolean
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of voucher templates
 */
router.get('/', voucherTemplateController.getAllVoucherTemplates);

/**
 * @swagger
 * /voucher_templates:
 *   post:
 *     summary: Create a new voucher template
 *     tags: [Voucher Templates]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/VoucherTemplate'
 *     responses:
 *       201:
 *         description: Template created successfully
 */
router.post('/', voucherTemplateController.createVoucherTemplate);

// ===== PUBLIC TEMPLATES =====

/**
 * @swagger
 * /voucher_templates/public:
 *   get:
 *     summary: Get public templates (visible in storefront)
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: query
 *         name: tenantId
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: List of public templates
 */
router.get('/public', voucherTemplateController.getPublicVoucherTemplates);

// ===== ACTIVE TEMPLATES =====

/**
 * @swagger
 * /voucher_templates/active:
 *   get:
 *     summary: Get active templates with valid dates
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: query
 *         name: tenantId
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: List of active templates
 */
router.get('/active', voucherTemplateController.getActiveVoucherTemplates);

// ===== EXPIRING TEMPLATES =====

/**
 * @swagger
 * /voucher_templates/expiring:
 *   get:
 *     summary: Get templates expiring soon
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days threshold
 *       - in: query
 *         name: tenantId
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: List of expiring templates
 */
router.get('/expiring', voucherTemplateController.getExpiringVoucherTemplates);

// ===== TENANT ROUTES =====

/**
 * @swagger
 * /voucher_templates/tenant/{tenantId}:
 *   get:
 *     summary: Get all voucher templates for a specific tenant
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: tenantId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: include_inactive
 *         schema:
 *           type: boolean
 *         description: Include inactive templates
 *     responses:
 *       200:
 *         description: List of voucher templates for the tenant
 */
router.get('/tenant/:tenantId', voucherTemplateController.getVoucherTemplatesByTenantId);

/**
 * @swagger
 * /voucher_templates/tenant/{tenantId}/count:
 *   get:
 *     summary: Count templates for a tenant
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: tenantId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Template count
 */
router.get('/tenant/:tenantId/count', voucherTemplateController.countVoucherTemplatesByTenant);

// ===== MERCHANT ROUTES =====

/**
 * @swagger
 * /voucher_templates/merchant/{merchantId}:
 *   get:
 *     summary: Get all voucher templates for a specific merchant
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: merchantId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: List of voucher templates for the merchant
 */
router.get('/merchant/:merchantId', voucherTemplateController.getVoucherTemplatesByMerchantId);

// ===== TYPE ROUTES =====

/**
 * @swagger
 * /voucher_templates/type/{type}:
 *   get:
 *     summary: Get templates by voucher type
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: type
 *         required: true
 *         schema:
 *           type: string
 *           enum: [fixed_amount, percentage, open_cash]
 *       - in: query
 *         name: tenantId
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: List of templates by type
 */
router.get('/type/:type', voucherTemplateController.getVoucherTemplatesByType);

// ===== SINGLE TEMPLATE ROUTES =====

/**
 * @swagger
 * /voucher_templates/{id}:
 *   get:
 *     summary: Get a voucher template by ID
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Voucher template details
 */
router.get('/:id', voucherTemplateController.getVoucherTemplateById);

/**
 * @swagger
 * /voucher_templates/{id}:
 *   put:
 *     summary: Update a voucher template
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/VoucherTemplate'
 *     responses:
 *       200:
 *         description: Template updated successfully
 */
router.put('/:id', voucherTemplateController.updateVoucherTemplate);

/**
 * @swagger
 * /voucher_templates/{id}:
 *   delete:
 *     summary: Permanently delete a voucher template
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       204:
 *         description: Template deleted successfully
 */
router.delete('/:id', voucherTemplateController.deleteVoucherTemplate);

/**
 * @swagger
 * /voucher_templates/{id}/deactivate:
 *   patch:
 *     summary: Soft delete (deactivate) a voucher template
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               updated_by:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       200:
 *         description: Template deactivated successfully
 */
router.patch('/:id/deactivate', voucherTemplateController.deactivateVoucherTemplate);

/**
 * @swagger
 * /voucher_templates/{id}/duplicate:
 *   post:
 *     summary: Duplicate a voucher template
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - created_by
 *             properties:
 *               new_name:
 *                 type: string
 *               created_by:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       201:
 *         description: Template duplicated successfully
 */
router.post('/:id/duplicate', voucherTemplateController.duplicateVoucherTemplate);

/**
 * @swagger
 * /voucher_templates/{id}/stats:
 *   get:
 *     summary: Get usage statistics for a template
 *     tags: [Voucher Templates]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Template usage statistics
 */
router.get('/:id/stats', voucherTemplateController.getVoucherTemplateStats);

// ===== BULK OPERATIONS =====

/**
 * @swagger
 * /voucher_templates/bulk/update:
 *   patch:
 *     summary: Bulk update multiple templates
 *     tags: [Voucher Templates]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ids
 *             properties:
 *               ids:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: uuid
 *               updates:
 *                 type: object
 *                 properties:
 *                   is_active:
 *                     type: boolean
 *                   is_public_visible:
 *                     type: boolean
 *     responses:
 *       200:
 *         description: Templates updated successfully
 */
router.patch('/bulk/update', voucherTemplateController.bulkUpdateVoucherTemplates);

module.exports = router;