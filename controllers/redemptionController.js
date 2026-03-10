const Redemption = require('../models/Redemption');

exports.getAllRedemptions = async (req, res) => {
  try {
    const filters = {
      voucher_id: req.query.voucher_id,
      merchant_id: req.query.merchant_id,
      status: req.query.status,
      redemption_method: req.query.redemption_method,
      date_from: req.query.date_from,
      date_to: req.query.date_to,
    };
    const redemptions = await Redemption.getAll(filters);
    res.json({ data: redemptions, count: redemptions.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getRedemptionById = async (req, res) => {
  try {
    const redemption = await Redemption.getById(req.params.id);
    if (!redemption) {
      return res.status(404).json({ error: 'Redemption not found' });
    }
    res.json(redemption);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createRedemption = async (req, res) => {
  try {
    const redemption = await Redemption.create({ ...req.body, created_by: req.user?.id });
    res.status(201).json(redemption);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.reverseRedemption = async (req, res) => {
  try {
    const redemption = await Redemption.reversal(req.params.id, {
      reason: req.body.reason,
      reversed_by: req.user?.id,
    });
    if (!redemption) {
      return res.status(404).json({ error: 'Redemption not found' });
    }
    res.json(redemption);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
