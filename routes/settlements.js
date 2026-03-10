const express = require('express');
const router = express.Router();
const settlementController = require('../controllers/settlementController');

/**
 * @swagger
 * tags:
 *   - name: Settlements
 *     description: Merchant payment settlements for redeemed vouchers
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Settlement:
 *       type: object
 *       required:
 *         - merchant_id
 *         - period_start
 *         - period_end
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique identifier for the settlement
 *         merchant_id:
 *           type: string
 *           format: uuid
 *           description: Reference to the merchant
 *         settlement_number:
 *           type: string
 *           description: Unique settlement number (auto-generated)
 *         period_start:
 *           type: string
 *           format: date
 *           description: Start date of settlement period
 *         period_end:
 *           type: string
 *           format: date
 *           description: End date of settlement period
 *         total_redemptions:
 *           type: integer
 *           description: Count of redemptions in period
 *         total_amount:
 *           type: number
 *           format: decimal
 *           description: Total value of redemptions
 *         rfa_fees:
 *           type: number
 *           format: decimal
 *           description: RFA service fees charged
 *         fee_percentage:
 *           type: number
 *           format: decimal
 *           description: Fee percentage applied
 *         net_payable:
 *           type: number
 *           format: decimal
 *           description: Net amount payable to merchant (total_amount - rfa_fees)
 *         status:
 *           type: string
 *           enum: [draft, submitted, approved, processed, paid, disputed]
 *           description: Settlement status
 *         payment_status:
 *           type: string
 *           enum: [pending, paid, failed]
 *           description: Payment status
 *         payment_method:
 *           type: string
 *           enum: [bank_transfer, check, mobile_money, wallet]
 *           description: Payment method for settlement
 *         payment_reference:
 *           type: string
 *           description: Payment transaction reference
 *         payment_date:
 *           type: string
 *           format: date-time
 *           description: When payment was made
 *         invoice_number:
 *           type: string
 *           description: Associated invoice number
 *         notes:
 *           type: string
 *           description: Additional notes
 *         created_at:
 *           type: string
 *           format: date-time
 *           description: Creation timestamp
 *         updated_at:
 *           type: string
 *           format: date-time
 *           description: Last update timestamp
 */

/**
 * @swagger
 * /settlements:
 *   get:
 *     tags:
 *       - Settlements
 *     summary: List all settlements with optional filters
 *     parameters:
 *       - in: query
 *         name: merchant_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by merchant
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [draft, submitted, approved, processed, paid, disputed]
 *         description: Filter by settlement status
 *       - in: query
 *         name: period_from
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter settlements from this date
 *       - in: query
 *         name: period_to
 *         schema:
 *           type: string
 *           format: date
 *         description: Filter settlements until this date
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by settlement number or invoice number
 *     responses:
 *       200:
 *         description: List of settlements
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Settlement'
 *                 count:
 *                   type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/', settlementController.getAllSettlements);

/**
 * @swagger
 * /settlements:
 *   post:
 *     tags:
 *       - Settlements
 *     summary: Create a new settlement
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Settlement'
 *           example:
 *             merchant_id: 550e8400-e29b-41d4-a716-446655440000
 *             period_start: 2026-02-01
 *             period_end: 2026-02-28
 *             total_redemptions: 50
 *             total_amount: 5000
 *             rfa_fees: 250
 *             fee_percentage: 5
 *             status: submitted
 *             payment_method: bank_transfer
 *     responses:
 *       201:
 *         description: Settlement created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Settlement'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 */
router.post('/', settlementController.createSettlement);

/**
 * @swagger
 * /settlements/{id}:
 *   get:
 *     tags:
 *       - Settlements
 *     summary: Get a settlement by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Settlement ID
 *     responses:
 *       200:
 *         description: Settlement details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Settlement'
 *       404:
 *         description: Settlement not found
 *       401:
 *         description: Unauthorized
 */
router.get('/:id', settlementController.getSettlementById);

/**
 * @swagger
 * /settlements/{id}/status:
 *   put:
 *     tags:
 *       - Settlements
 *     summary: Update settlement status
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Settlement ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [draft, submitted, approved, processed, paid, disputed]
 *                 description: New settlement status
 *     responses:
 *       200:
 *         description: Settlement status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Settlement'
 *       404:
 *         description: Settlement not found
 *       401:
 *         description: Unauthorized
 */
router.put('/:id/status', settlementController.updateSettlementStatus);

/**
 * @swagger
 * /settlements/{id}:
 *   delete:
 *     tags:
 *       - Settlements
 *     summary: Delete a settlement
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Settlement ID
 *     responses:
 *       204:
 *         description: Settlement deleted successfully
 *       404:
 *         description: Settlement not found
 *       401:
 *         description: Unauthorized
 */
router.delete('/:id', settlementController.deleteSettlement);

module.exports = router;
