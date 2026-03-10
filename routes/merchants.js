const express = require('express');
const router = express.Router();
const merchantController = require('../controllers/merchantController');

/**
 * @swagger
 * tags:
 *   - name: Merchants
 *     description: Merchant store locations and management
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Merchant:
 *       type: object
 *       required:
 *         - tenant_id
 *         - merchant_name
 *         - merchant_code
 *         - email
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique identifier for the merchant
 *         tenant_id:
 *           type: string
 *           format: uuid
 *           description: The ID of the tenant the merchant belongs to
 *         merchant_name:
 *           type: string
 *           description: Name of the merchant store
 *         merchant_code:
 *           type: string
 *           description: Unique code identifier for the merchant
 *         merchant_category:
 *           type: string
 *           enum: [retail, restaurant, entertainment, services, other]
 *           description: Category of merchant business
 *         contact_person:
 *           type: string
 *           description: Name of contact person
 *         email:
 *           type: string
 *           format: email
 *           description: Email address
 *         phone:
 *           type: string
 *           description: Phone number
 *         address:
 *           type: string
 *           description: Physical address
 *         latitude:
 *           type: number
 *           format: double
 *           description: Geographic latitude
 *         longitude:
 *           type: number
 *           format: double
 *           description: Geographic longitude
 *         settlement_period:
 *           type: string
 *           enum: [daily, weekly, monthly, quarterly]
 *           description: Settlement period for payments
 *         is_active:
 *           type: boolean
 *           description: Active status
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
 * /merchants:
 *   get:
 *     tags:
 *       - Merchants
 *     summary: List all merchants with optional filters
 *     parameters:
 *       - in: query
 *         name: tenant_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by tenant ID
 *       - in: query
 *         name: merchant_category
 *         schema:
 *           type: string
 *           enum: [retail, restaurant, entertainment, services, other]
 *         description: Filter by merchant category
 *       - in: query
 *         name: is_active
 *         schema:
 *           type: boolean
 *         description: Filter by active status
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by merchant name or code
 *     responses:
 *       200:
 *         description: List of merchants
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Merchant'
 *                 count:
 *                   type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/', merchantController.getAllMerchants);

/**
 * @swagger
 * /merchants:
 *   post:
 *     tags:
 *       - Merchants
 *     summary: Create a new merchant
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Merchant'
 *           example:
 *             tenant_id: 550e8400-e29b-41d4-a716-446655440000
 *             merchant_name: ABC Store
 *             merchant_code: ABC001
 *             merchant_category: retail
 *             contact_person: John Doe
 *             email: john@abcstore.com
 *             phone: +1234567890
 *             address: 123 Main St, City
 *             latitude: 40.7128
 *             longitude: -74.0060
 *             settlement_period: weekly
 *     responses:
 *       201:
 *         description: Merchant created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Merchant'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 */
router.post('/', merchantController.createMerchant);

/**
 * @swagger
 * /merchants/{id}:
 *   get:
 *     tags:
 *       - Merchants
 *     summary: Get a merchant by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Merchant ID
 *     responses:
 *       200:
 *         description: Merchant details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Merchant'
 *       404:
 *         description: Merchant not found
 *       401:
 *         description: Unauthorized
 */
router.get('/:id', merchantController.getMerchantById);

/**
 * @swagger
 * /merchants/{id}:
 *   put:
 *     tags:
 *       - Merchants
 *     summary: Update a merchant
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Merchant ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Merchant'
 *     responses:
 *       200:
 *         description: Merchant updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Merchant'
 *       404:
 *         description: Merchant not found
 *       401:
 *         description: Unauthorized
 */
router.put('/:id', merchantController.updateMerchant);

/**
 * @swagger
 * /merchants/{id}:
 *   delete:
 *     tags:
 *       - Merchants
 *     summary: Delete a merchant
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Merchant ID
 *     responses:
 *       204:
 *         description: Merchant deleted successfully
 *       404:
 *         description: Merchant not found
 *       401:
 *         description: Unauthorized
 */
router.delete('/:id', merchantController.deleteMerchant);

module.exports = router;