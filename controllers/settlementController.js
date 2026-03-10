const Settlement = require('../models/Settlement');

exports.getAllSettlements = async (req, res) => {
  try {
    const filters = {
      merchant_id: req.query.merchant_id,
      status: req.query.status,
      period_from: req.query.period_from,
      period_to: req.query.period_to,
      search: req.query.search,
    };
    const settlements = await Settlement.getAll(filters);
    res.json({ data: settlements, count: settlements.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getSettlementById = async (req, res) => {
  try {
    const settlement = await Settlement.getById(req.params.id);
    if (!settlement) {
      return res.status(404).json({ error: 'Settlement not found' });
    }
    res.json(settlement);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createSettlement = async (req, res) => {
  try {
    const settlement = await Settlement.create({ ...req.body, created_by: req.user?.id });
    res.status(201).json(settlement);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateSettlementStatus = async (req, res) => {
  try {
    const settlement = await Settlement.updateStatus(req.params.id, req.body.status);
    if (!settlement) {
      return res.status(404).json({ error: 'Settlement not found' });
    }
    res.json(settlement);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deleteSettlement = async (req, res) => {
  try {
    const settlement = await Settlement.delete(req.params.id);
    if (!settlement) {
      return res.status(404).json({ error: 'Settlement not found' });
    }
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
