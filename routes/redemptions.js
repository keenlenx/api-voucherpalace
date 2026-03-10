const express = require('express');
const router = express.Router();
const redemptionController = require('../controllers/redemptionController');

/**
 * @swagger
 * tags:
 *   - name: Redemptions
 *     description: Voucher redemption transactions and tracking
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Redemption:
 *       type: object
 *       required:
 *         - voucher_id
 *         - merchant_id
 *         - amount_redeemed
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique identifier for the redemption
 *         voucher_id:
 *           type: string
 *           format: uuid
 *           description: Reference to the voucher being redeemed
 *         merchant_id:
 *           type: string
 *           format: uuid
 *           description: Merchant where redemption occurred
 *         amount_redeemed:
 *           type: number
 *           format: decimal
 *           description: Amount redeemed in this transaction
 *         previous_balance:
 *           type: number
 *           format: decimal
 *           description: Balance before redemption
 *         new_balance:
 *           type: number
 *           format: decimal
 *           description: Balance after redemption
 *         redemption_method:
 *           type: string
 *           enum: [code_entry, qr_scan, phone_lookup, nfc]
 *           description: Method used for redemption
 *         receipt_number:
 *           type: string
 *           description: Receipt or transaction reference number
 *         status:
 *           type: string
 *           enum: [completed, reversed, pending]
 *           description: Status of the redemption
 *         redemption_date:
 *           type: string
 *           format: date-time
 *           description: When the redemption occurred
 *         reversed_at:
 *           type: string
 *           format: date-time
 *           description: When the redemption was reversed (if applicable)
 *         reversed_by:
 *           type: string
 *           format: uuid
 *           description: User ID who reversed the redemption
 *         reversal_reason:
 *           type: string
 *           description: Reason for reversal
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
 * /redemptions:
 *   get:
 *     tags:
 *       - Redemptions
 *     summary: List all redemptions with optional filters
 *     parameters:
 *       - in: query
 *         name: voucher_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by voucher
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
 *           enum: [completed, reversed, pending]
 *         description: Filter by redemption status
 *       - in: query
 *         name: redemption_method
 *         schema:
 *           type: string
 *           enum: [code_entry, qr_scan, phone_lookup, nfc]
 *         description: Filter by redemption method
 *       - in: query
 *         name: date_from
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter redemptions from this date
 *       - in: query
 *         name: date_to
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter redemptions until this date
 *     responses:
 *       200:
 *         description: List of redemptions
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Redemption'
 *                 count:
 *                   type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/', redemptionController.getAllRedemptions);

/**
 * @swagger
 * /redemptions:
 *   post:
 *     tags:
 *       - Redemptions
 *     summary: Create a new redemption
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Redemption'
 *           example:
 *             voucher_id: 550e8400-e29b-41d4-a716-446655440000
 *             merchant_id: 550e8400-e29b-41d4-a716-446655440001
 *             amount_redeemed: 50
 *             redemption_method: qr_scan
 *             receipt_number: RCP20260219001
 *     responses:
 *       201:
 *         description: Redemption created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Redemption'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 */
router.post('/', redemptionController.createRedemption);

/**
 * @swagger
 * /redemptions/{id}:
 *   get:
 *     tags:
 *       - Redemptions
 *     summary: Get a redemption by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Redemption ID
 *     responses:
 *       200:
 *         description: Redemption details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Redemption'
 *       404:
 *         description: Redemption not found
 *       401:
 *         description: Unauthorized
 */
router.get('/:id', redemptionController.getRedemptionById);

/**
 * @swagger
 * /redemptions/{id}/reverse:
 *   post:
 *     tags:
 *       - Redemptions
 *     summary: Reverse a redemption transaction
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Redemption ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - reason
 *             properties:
 *               reason:
 *                 type: string
 *                 description: Reason for reversal
 *     responses:
 *       200:
 *         description: Redemption reversed successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Redemption'
 *       404:
 *         description: Redemption not found
 *       401:
 *         description: Unauthorized
 */
router.post('/:id/reverse', redemptionController.reverseRedemption);

module.exports = router;
