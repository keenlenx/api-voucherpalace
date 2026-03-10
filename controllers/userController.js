const User = require('../models/User');
const bcrypt = require('bcryptjs');

exports.getAllUsers = async (req, res) => {
  try {
    const filters = {
      tenant_id: req.query.tenant_id,
      role: req.query.role,
      status: req.query.status,
      search: req.query.search
    };
    const users = await User.getAll(filters);
    res.json({
      success: true,
      data: users,
      count: users.length
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await User.getById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.createUser = async (req, res) => {
  try {
    const { email, password, first_name, last_name, phone, role, tenant_id } = req.body;

    // Check if user exists
    const existingUser = await User.getByEmail(email);
    if (existingUser) {
      return res.status(409).json({ success: false, error: 'Email already exists' });
    }

    // Hash password
    const password_hash = await bcrypt.hash(password || 'Welcome123!', 10);

    const user = await User.create({
      tenant_id,
      email,
      password_hash,
      first_name,
      last_name,
      phone,
      role,
      created_by: req.user?.user_id
    });

    res.status(201).json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
        role: user.role,
        tenant_id: user.tenant_id
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.updateUser = async (req, res) => {
  try {
    const user = await User.getById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Check email uniqueness if being updated
    if (req.body.email && req.body.email !== user.email) {
      const existingUser = await User.getByEmail(req.body.email);
      if (existingUser) {
        return res.status(409).json({ success: false, error: 'Email already exists' });
      }
    }

    const updatedUser = await User.update(req.params.id, {
      ...req.body,
      updated_by: req.user?.user_id
    });

    res.json({
      success: true,
      data: {
        id: updatedUser.id,
        email: updatedUser.email,
        first_name: updatedUser.first_name,
        last_name: updatedUser.last_name,
        phone: updatedUser.phone,
        role: updatedUser.role,
        status: updatedUser.status
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// Soft delete
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.getById(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Don't allow deleting yourself
    if (req.params.id === req.user?.user_id) {
      return res.status(400).json({ success: false, error: 'Cannot delete your own account' });
    }

    await User.softDelete(req.params.id, req.user?.user_id);

    res.status(200).json({ 
      success: true, 
      message: 'User deactivated successfully' 
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// Restore soft-deleted user
exports.restoreUser = async (req, res) => {
  try {
    const user = await User.getByIdIncludingDeleted(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    await User.restore(req.params.id);

    res.json({ 
      success: true, 
      message: 'User restored successfully' 
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};