const express = require('express');
const router = express.Router();
const tenantController = require('../controllers/tenantController');

/**
 * @swagger
 * tags:
 *   - name: Tenants
 *     description: Client companies and merchants using the platform
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Tenant:
 *       type: object
 *       required:
 *         - tenant_name
 *         - tenant_type
 *         - email
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique identifier for the tenant
 *         tenant_name:
 *           type: string
 *           description: Name of the tenant company
 *         tenant_type:
 *           type: string
 *           enum: [corporate, merchant, rfa_internal]
 *           description: Type of tenant
 *         registration_number:
 *           type: string
 *           description: Company registration number
 *         tax_id:
 *           type: string
 *           description: Tax identification number
 *         email:
 *           type: string
 *           format: email
 *           description: Contact email
 *         phone:
 *           type: string
 *           description: Contact phone number
 *         address:
 *           type: string
 *           description: Physical address
 *         website:
 *           type: string
 *           format: uri
 *           description: Company website
 *         logo_url:
 *           type: string
 *           format: uri
 *           description: Logo URL
 *         status:
 *           type: string
 *           enum: [active, suspended, pending]
 *           description: Tenant status
 *         wallet_balance:
 *           type: number
 *           format: decimal
 *           description: Pre-paid funds available
 *         credit_limit:
 *           type: number
 *           format: decimal
 *           description: Credit line for post-paid vouchers
 *         billing_cycle:
 *           type: string
 *           enum: [monthly, quarterly, annual]
 *           description: Billing cycle
 *         is_active:
 *           type: boolean
 *           description: Tenant active status
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
 * /tenants:
 *   get:
 *     tags:
 *       - Tenants
 *     summary: List all tenants with optional filters
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, suspended, pending]
 *         description: Filter by status
 *       - in: query
 *         name: tenant_type
 *         schema:
 *           type: string
 *           enum: [corporate, merchant, rfa_internal]
 *         description: Filter by tenant type
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by name or email
 *     responses:
 *       200:
 *         description: List of tenants
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Tenant'
 *                 count:
 *                   type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/', tenantController.getAllTenants);

/**
 * @swagger
 * /tenants:
 *   post:
 *     tags:
 *       - Tenants
 *     summary: Create a new tenant
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Tenant'
 *           example:
 *             tenant_name: ABC Corporation
 *             tenant_type: corporate
 *             registration_number: REG123456
 *             tax_id: TAX123456
 *             email: info@abccorp.com
 *             phone: +1234567890
 *             address: 100 Business St, City
 *             website: https://www.abccorp.com
 *             billing_cycle: monthly
 *     responses:
 *       201:
 *         description: Tenant created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Tenant'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 */
router.post('/', tenantController.createTenant);

/**
 * @swagger
 * /tenants/{id}:
 *   get:
 *     tags:
 *       - Tenants
 *     summary: Get a tenant by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Tenant ID
 *     responses:
 *       200:
 *         description: Tenant details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Tenant'
 *       404:
 *         description: Tenant not found
 *       401:
 *         description: Unauthorized
 */
router.get('/:id', tenantController.getTenantById);

/**
 * @swagger
 * /tenants/{id}:
 *   put:
 *     tags:
 *       - Tenants
 *     summary: Update a tenant
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Tenant ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Tenant'
 *     responses:
 *       200:
 *         description: Tenant updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Tenant'
 *       404:
 *         description: Tenant not found
 *       401:
 *         description: Unauthorized
 */
router.put('/:id', tenantController.updateTenant);

/**
 * @swagger
 * /tenants/{id}:
 *   delete:
 *     tags:
 *       - Tenants
 *     summary: Delete a tenant
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Tenant ID
 *     responses:
 *       204:
 *         description: Tenant deleted successfully
 *       404:
 *         description: Tenant not found
 *       401:
 *         description: Unauthorized
 */
router.delete('/:id', tenantController.deleteTenant);

module.exports = router;