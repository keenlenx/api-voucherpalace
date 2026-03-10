const express = require('express');
const router = express.Router();
const voucherController = require('../controllers/voucherController');

/**
 * @swagger
 * tags:
 *   - name: Vouchers
 *     description: Individual issued voucher instances
 *   - name: Voucher Analytics
 *     description: Analytics and statistics for vouchers
 *   - name: Voucher Redemption
 *     description: Voucher redemption operations
 *   - name: Voucher Batch
 *     description: Batch operations for vouchers
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Voucher:
 *       type: object
 *       required:
 *         - tenant_id
 *         - voucher_template_id
 *         - original_value
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         tenant_id:
 *           type: string
 *           format: uuid
 *         voucher_template_id:
 *           type: string
 *           format: uuid
 *         code:
 *           type: string
 *         original_value:
 *           type: number
 *         remaining_value:
 *           type: number
 *         status:
 *           type: string
 *           enum: [active, redeemed, expired, refunded, cancelled]
 *         beneficiary_name:
 *           type: string
 *         beneficiary_email:
 *           type: string
 *         beneficiary_phone:
 *           type: string
 *         distribution_method:
 *           type: string
 *         distribution_date:
 *           type: string
 *           format: date-time
 *         issued_date:
 *           type: string
 *           format: date-time
 *         expires_at:
 *           type: string
 *           format: date-time
 *         batch_id:
 *           type: string
 *         notes:
 *           type: string
 *         created_at:
 *           type: string
 *           format: date-time
 *         updated_at:
 *           type: string
 *           format: date-time
 *     
 *     Redemption:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         voucher_id:
 *           type: string
 *           format: uuid
 *         amount:
 *           type: number
 *         previous_balance:
 *           type: number
 *         new_balance:
 *           type: number
 *         redeemed_by:
 *           type: string
 *         redeemed_by_email:
 *           type: string
 *         metadata:
 *           type: object
 *         created_at:
 *           type: string
 *           format: date-time
 *     
 *     VoucherStats:
 *       type: object
 *       properties:
 *         total_vouchers:
 *           type: integer
 *         active_count:
 *           type: integer
 *         redeemed_count:
 *           type: integer
 *         expired_count:
 *           type: integer
 *         total_value:
 *           type: number
 *         remaining_value:
 *           type: number
 *         redeemed_value:
 *           type: number
 *         template_count:
 *           type: integer
 *         unique_beneficiaries:
 *           type: integer
 *         trend:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               date:
 *                 type: string
 *               issued:
 *                 type: integer
 *               redeemed:
 *                 type: integer
 *     
 *     BatchStatus:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         batch_reference:
 *           type: string
 *         tenant_id:
 *           type: string
 *         voucher_template_id:
 *           type: string
 *         template_name:
 *           type: string
 *         total_count:
 *           type: integer
 *         successful_count:
 *           type: integer
 *         failed_count:
 *           type: integer
 *         status:
 *           type: string
 *           enum: [pending, processing, completed, failed]
 *         vouchers:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               id:
 *                 type: string
 *               code:
 *                 type: string
 *               status:
 *                 type: string
 *               beneficiary_name:
 *                 type: string
 */

// ===== BATCH OPERATIONS =====

/**
 * @swagger
 * /vouchers/bulk:
 *   post:
 *     tags: [Vouchers, Voucher Batch]
 *     summary: Bulk create vouchers for staff
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - template_id
 *               - staff_list
 *             properties:
 *               template_id:
 *                 type: string
 *                 format: uuid
 *               staff_list:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - name
 *                   properties:
 *                     name:
 *                       type: string
 *                     email:
 *                       type: string
 *                     phone:
 *                       type: string
 *                     employee_id:
 *                       type: string
 *                     department:
 *                       type: string
 *                     expiry_date:
 *                       type: string
 *                       format: date-time
 *     responses:
 *       200:
 *         description: Bulk creation completed
 */
router.post('/bulk', voucherController.bulkCreateVouchers);

/**
 * @swagger
 * /vouchers/batch/{batch_id}:
 *   get:
 *     tags: [Vouchers, Voucher Batch]
 *     summary: Get batch creation status
 *     parameters:
 *       - in: path
 *         name: batch_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Batch details and vouchers
 */
router.get('/batch/:batch_id', voucherController.getBatchStatus);

// ===== CORE VOUCHER OPERATIONS =====

/**
 * @swagger
 * /vouchers:
 *   get:
 *     tags: [Vouchers]
 *     summary: List all vouchers with optional filters
 *     parameters:
 *       - in: query
 *         name: tenant_id
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, redeemed, expired, refunded, cancelled]
 *       - in: query
 *         name: voucher_template_id
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: code
 *         schema:
 *           type: string
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of vouchers
 */
router.get('/', voucherController.getAllVouchers);

/**
 * @swagger
 * /vouchers:
 *   post:
 *     tags: [Vouchers]
 *     summary: Create a new voucher
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Voucher'
 *     responses:
 *       201:
 *         description: Voucher created successfully
 */
router.post('/', voucherController.createVoucher);

/**
 * @swagger
 * /vouchers/{id}:
 *   get:
 *     tags: [Vouchers]
 *     summary: Get a voucher by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Voucher details
 */
router.get('/:id', voucherController.getVoucherById);

/**
 * @swagger
 * /vouchers/code/{code}:
 *   get:
 *     tags: [Vouchers]
 *     summary: Get a voucher by code
 *     parameters:
 *       - in: path
 *         name: code
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Voucher details
 */
router.get('/code/:code', voucherController.getVoucherByCode);

/**
 * @swagger
 * /vouchers/{id}:
 *   put:
 *     tags: [Vouchers]
 *     summary: Update a voucher
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
 *             $ref: '#/components/schemas/Voucher'
 *     responses:
 *       200:
 *         description: Voucher updated successfully
 */
router.put('/:id', voucherController.updateVoucher);

/**
 * @swagger
 * /vouchers/{id}:
 *   delete:
 *     tags: [Vouchers]
 *     summary: Delete a voucher
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       204:
 *         description: Voucher deleted successfully
 */
router.delete('/:id', voucherController.deleteVoucher);

// ===== REDEMPTION OPERATIONS =====

/**
 * @swagger
 * /vouchers/{id}/redeem:
 *   post:
 *     tags: [Vouchers, Voucher Redemption]
 *     summary: Redeem a voucher
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
 *               - amount
 *             properties:
 *               amount:
 *                 type: number
 *               metadata:
 *                 type: object
 *     responses:
 *       200:
 *         description: Voucher redeemed successfully
 */
router.post('/:id/redeem', voucherController.redeemVoucher);

/**
 * @swagger
 * /vouchers/{id}/redemptions:
 *   get:
 *     tags: [Vouchers, Voucher Redemption]
 *     summary: Get redemption history for a voucher
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Redemption history
 */
router.get('/:id/redemptions', voucherController.getVoucherRedemptionHistory);

// ===== ANALYTICS & STATISTICS =====

/**
 * @swagger
 * /vouchers/stats:
 *   get:
 *     tags: [Vouchers, Voucher Analytics]
 *     summary: Get voucher statistics
 *     parameters:
 *       - in: query
 *         name: tenant_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *     responses:
 *       200:
 *         description: Voucher statistics
 */
router.get('/stats', voucherController.getVoucherStats);

/**
 * @swagger
 * /vouchers/expiring:
 *   get:
 *     tags: [Vouchers, Voucher Analytics]
 *     summary: Get vouchers expiring soon
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 7
 *       - in: query
 *         name: tenant_id
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: List of expiring vouchers
 */
router.get('/expiring', voucherController.getExpiringSoon);

/**
 * @swagger
 * /vouchers/performance/templates:
 *   get:
 *     tags: [Vouchers, Voucher Analytics]
 *     summary: Get performance metrics by template
 *     parameters:
 *       - in: query
 *         name: tenant_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *     responses:
 *       200:
 *         description: Template performance metrics
 */
router.get('/performance/templates', voucherController.getTemplatePerformance);

// ===== ADVANCED OPERATIONS =====

/**
 * @swagger
 * /vouchers/search/advanced:
 *   get:
 *     tags: [Vouchers]
 *     summary: Advanced search with multiple filters
 *     parameters:
 *       - in: query
 *         name: tenant_id
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: date_from
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: date_to
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: min_value
 *         schema:
 *           type: number
 *       - in: query
 *         name: max_value
 *         schema:
 *           type: number
 *       - in: query
 *         name: beneficiary
 *         schema:
 *           type: string
 *       - in: query
 *         name: template_id
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: has_redemptions
 *         schema:
 *           type: boolean
 *     responses:
 *       200:
 *         description: Advanced search results
 */
router.get('/search/advanced', voucherController.advancedSearch);

/**
 * @swagger
 * /vouchers/export:
 *   get:
 *     tags: [Vouchers]
 *     summary: Export vouchers for date range
 *     parameters:
 *       - in: query
 *         name: tenant_id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: start_date
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: end_date
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *     responses:
 *       200:
 *         description: Exported vouchers data
 */
router.get('/export', voucherController.exportVouchers);

// ===== BULK OPERATIONS =====

/**
 * @swagger
 * /vouchers/bulk/status:
 *   patch:
 *     tags: [Vouchers, Voucher Batch]
 *     summary: Bulk update voucher status
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ids
 *               - status
 *             properties:
 *               ids:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: uuid
 *               status:
 *                 type: string
 *                 enum: [active, redeemed, expired, refunded, cancelled]
 *     responses:
 *       200:
 *         description: Vouchers updated successfully
 */
router.patch('/bulk/status', voucherController.bulkUpdateStatus);

// ===== MAINTENANCE OPERATIONS =====

/**
 * @swagger
 * /vouchers/maintenance/mark-expired:
 *   post:
 *     tags: [Vouchers]
 *     summary: Mark expired vouchers (cron job)
 *     responses:
 *       200:
 *         description: Expired vouchers marked
 */
router.post('/maintenance/mark-expired', voucherController.markExpiredVouchers);

/**
 * @swagger
 * /vouchers/maintenance/cleanup:
 *   delete:
 *     tags: [Vouchers]
 *     summary: Clean up old records
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 365
 *     responses:
 *       200:
 *         description: Old records cleaned up
 */
router.delete('/maintenance/cleanup', voucherController.cleanupOldRecords);

// ===== BENEFICIARY OPERATIONS =====

/**
 * @swagger
 * /vouchers/beneficiary/transfer:
 *   post:
 *     tags: [Vouchers]
 *     summary: Transfer vouchers to new beneficiary email
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - old_email
 *               - new_email
 *             properties:
 *               old_email:
 *                 type: string
 *                 format: email
 *               new_email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Vouchers transferred successfully
 */
router.post('/beneficiary/transfer', voucherController.transferBeneficiary);

/**
 * @swagger
 * /vouchers/duplicates:
 *   get:
 *     tags: [Vouchers]
 *     summary: Find potential duplicate vouchers
 *     parameters:
 *       - in: query
 *         name: email
 *         required: true
 *         schema:
 *           type: string
 *           format: email
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 7
 *     responses:
 *       200:
 *         description: Potential duplicates found
 */
router.get('/duplicates', voucherController.findPotentialDuplicates);

module.exports = router;