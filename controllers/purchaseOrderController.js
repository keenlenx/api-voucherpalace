const PurchaseOrder = require('../models/PurchaseOrder');

exports.getAllPurchaseOrders = async (req, res) => {
  try {
    const filters = {
      voucher_template_id: req.query.voucher_template_id,
      consumer_email: req.query.consumer_email,
      payment_status: req.query.payment_status,
      order_type: req.query.order_type,
      date_from: req.query.date_from,
      date_to: req.query.date_to,
      search: req.query.search,
    };
    const orders = await PurchaseOrder.getAll(filters);
    res.json({ data: orders, count: orders.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getPurchaseOrderById = async (req, res) => {
  try {
    const order = await PurchaseOrder.getById(req.params.id);
    if (!order) {
      return res.status(404).json({ error: 'Purchase order not found' });
    }
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createPurchaseOrder = async (req, res) => {
  try {
    const order = await PurchaseOrder.create({ ...req.body, created_by: req.user?.id });
    res.status(201).json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updatePaymentStatus = async (req, res) => {
  try {
    const order = await PurchaseOrder.updatePaymentStatus(req.params.id, req.body.payment_status);
    if (!order) {
      return res.status(404).json({ error: 'Purchase order not found' });
    }
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deletePurchaseOrder = async (req, res) => {
  try {
    const order = await PurchaseOrder.delete(req.params.id);
    if (!order) {
      return res.status(404).json({ error: 'Purchase order not found' });
    }
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
