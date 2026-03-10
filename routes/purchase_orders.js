const express = require('express');
const router = express.Router();
const purchaseOrderController = require('../controllers/purchaseOrderController');

/**
 * @swagger
 * tags:
 *   - name: Purchase Orders
 *     description: Consumer e-commerce purchases from public storefront
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     PurchaseOrder:
 *       type: object
 *       required:
 *         - voucher_template_id
 *         - quantity
 *         - consumer_email
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique identifier for the purchase order
 *         order_number:
 *           type: string
 *           description: Unique order number (auto-generated)
 *         voucher_template_id:
 *           type: string
 *           format: uuid
 *           description: Reference to the voucher template being purchased
 *         quantity:
 *           type: integer
 *           description: Number of vouchers purchased
 *         unit_price:
 *           type: number
 *           format: decimal
 *           description: Price per unit at time of purchase
 *         total_amount:
 *           type: number
 *           format: decimal
 *           description: Total order amount (quantity * unit_price)
 *         payment_status:
 *           type: string
 *           enum: [pending, paid, failed, refunded]
 *           description: Payment status of the order
 *         order_type:
 *           type: string
 *           enum: [self, gift]
 *           description: Whether order is for self or gift
 *         consumer_name:
 *           type: string
 *           description: Name of the consumer
 *         consumer_email:
 *           type: string
 *           format: email
 *           description: Email of the consumer
 *         consumer_phone:
 *           type: string
 *           description: Phone number of the consumer
 *         recipient_name:
 *           type: string
 *           description: Name of gift recipient (if order_type is gift)
 *         recipient_email:
 *           type: string
 *           format: email
 *           description: Email of gift recipient
 *         recipient_phone:
 *           type: string
 *           description: Phone of gift recipient
 *         delivery_type:
 *           type: string
 *           enum: [immediate, scheduled]
 *           description: Delivery type
 *         scheduled_delivery_date:
 *           type: string
 *           format: date-time
 *           description: Scheduled delivery date (if applicable)
 *         gift_message:
 *           type: string
 *           description: Custom message for gift
 *         payment_method:
 *           type: string
 *           enum: [card, bank_transfer, mobile_money, wallet]
 *           description: Payment method used
 *         transaction_reference:
 *           type: string
 *           description: Payment gateway transaction reference
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
 * /purchase_orders:
 *   get:
 *     tags:
 *       - Purchase Orders
 *     summary: List all purchase orders with optional filters
 *     parameters:
 *       - in: query
 *         name: voucher_template_id
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Filter by voucher template
 *       - in: query
 *         name: consumer_email
 *         schema:
 *           type: string
 *           format: email
 *         description: Filter by consumer email
 *       - in: query
 *         name: payment_status
 *         schema:
 *           type: string
 *           enum: [pending, paid, failed, refunded]
 *         description: Filter by payment status
 *       - in: query
 *         name: order_type
 *         schema:
 *           type: string
 *           enum: [self, gift]
 *         description: Filter by order type
 *       - in: query
 *         name: date_from
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter orders from this date
 *       - in: query
 *         name: date_to
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Filter orders until this date
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by order number or consumer email
 *     responses:
 *       200:
 *         description: List of purchase orders
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/PurchaseOrder'
 *                 count:
 *                   type: integer
 *       401:
 *         description: Unauthorized
 */
router.get('/', purchaseOrderController.getAllPurchaseOrders);

/**
 * @swagger
 * /purchase_orders:
 *   post:
 *     tags:
 *       - Purchase Orders
 *     summary: Create a new purchase order
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/PurchaseOrder'
 *           example:
 *             voucher_template_id: 550e8400-e29b-41d4-a716-446655440000
 *             quantity: 5
 *             consumer_name: Jane Doe
 *             consumer_email: jane@example.com
 *             consumer_phone: +1234567890
 *             order_type: self
 *             payment_method: card
 *     responses:
 *       201:
 *         description: Purchase order created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/PurchaseOrder'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 */
router.post('/', purchaseOrderController.createPurchaseOrder);

/**
 * @swagger
 * /purchase_orders/{id}:
 *   get:
 *     tags:
 *       - Purchase Orders
 *     summary: Get a purchase order by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase Order ID
 *     responses:
 *       200:
 *         description: Purchase order details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/PurchaseOrder'
 *       404:
 *         description: Purchase order not found
 *       401:
 *         description: Unauthorized
 */
router.get('/:id', purchaseOrderController.getPurchaseOrderById);

/**
 * @swagger
 * /purchase_orders/{id}/payment-status:
 *   put:
 *     tags:
 *       - Purchase Orders
 *     summary: Update payment status of a purchase order
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase Order ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - payment_status
 *             properties:
 *               payment_status:
 *                 type: string
 *                 enum: [pending, paid, failed, refunded]
 *                 description: New payment status
 *     responses:
 *       200:
 *         description: Payment status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/PurchaseOrder'
 *       404:
 *         description: Purchase order not found
 *       401:
 *         description: Unauthorized
 */
router.put('/:id/payment-status', purchaseOrderController.updatePaymentStatus);

/**
 * @swagger
 * /purchase_orders/{id}:
 *   delete:
 *     tags:
 *       - Purchase Orders
 *     summary: Delete a purchase order
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Purchase Order ID
 *     responses:
 *       204:
 *         description: Purchase order deleted successfully
 *       404:
 *         description: Purchase order not found
 *       401:
 *         description: Unauthorized
 */
router.delete('/:id', purchaseOrderController.deletePurchaseOrder);

module.exports = router;
