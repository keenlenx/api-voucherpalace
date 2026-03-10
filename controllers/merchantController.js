const Merchant = require('../models/Merchant');

exports.getAllMerchants = async (req, res) => {
  try {
    const merchants = await Merchant.getAll();
    res.json(merchants);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getMerchantById = async (req, res) => {
  try {
    const merchant = await Merchant.getById(req.params.id);
    if (!merchant) {
      return res.status(404).json({ error: 'Merchant not found' });
    }
    res.json(merchant);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createMerchant = async (req, res) => {
  try {
    const merchant = await Merchant.create(req.body);
    res.status(201).json(merchant);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateMerchant = async (req, res) => {
  try {
    const merchant = await Merchant.update(req.params.id, req.body);
    if (!merchant) {
      return res.status(404).json({ error: 'Merchant not found' });
    }
    res.json(merchant);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deleteMerchant = async (req, res) => {
  try {
    const merchant = await Merchant.delete(req.params.id);
    if (!merchant) {
      return res.status(404).json({ error: 'Merchant not found' });
    }
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};