const Tenant = require('../models/Tenant');

exports.getAllTenants = async (req, res) => {
  try {
    const filters = {
      status: req.query.status,
      tenant_type: req.query.tenant_type,
      search: req.query.search,
    };
    const tenants = await Tenant.getAll(filters);
    res.json({ data: tenants, count: tenants.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getTenantById = async (req, res) => {
  try {
    const tenant = await Tenant.getById(req.params.id);
    if (!tenant) {
      return res.status(404).json({ error: 'Tenant not found' });
    }
    res.json(tenant);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createTenant = async (req, res) => {
  try {
    const tenant = await Tenant.create({ ...req.body, created_by: req.user?.id });
    res.status(201).json(tenant);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateTenant = async (req, res) => {
  try {
    const tenant = await Tenant.update(req.params.id, { ...req.body, updated_by: req.user?.id });
    if (!tenant) {
      return res.status(404).json({ error: 'Tenant not found' });
    }
    res.json(tenant);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deleteTenant = async (req, res) => {
  try {
    const tenant = await Tenant.delete(req.params.id);
    if (!tenant) {
      return res.status(404).json({ error: 'Tenant not found' });
    }
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};