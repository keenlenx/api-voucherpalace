const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const router = express.Router();
const User = require('../models/User');
const Tenant = require('../models/Tenant');
const mailer = require('../config/mailer');

/**
 * @swagger
 * tags:
 *   - name: Auth
 *     description: Authentication & User Self-Service
 *   - name: Admin
 *     description: Admin User Management
 */

/**
 * @swagger
 * components:
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 *   schemas:
 *     RegisterRequest:
 *       type: object
 *       required:
 *         - email
 *         - password
 *         - first_name
 *         - last_name
 *       properties:
 *         email:
 *           type: string
 *         password:
 *           type: string
 *         first_name:
 *           type: string
 *         last_name:
 *           type: string
 *         phone:
 *           type: string
 *         tenant_id:
 *           type: string
 *
 *     LoginRequest:
 *       type: object
 *       required:
 *         - identifier
 *         - password
 *       properties:
 *         identifier:
 *           type: string
 *         password:
 *           type: string
 *
 *     ForgotPasswordRequest:
 *       type: object
 *       required:
 *         - email
 *       properties:
 *         email:
 *           type: string
 *
 *     ResetPasswordRequest:
 *       type: object
 *       required:
 *         - token
 *         - new_password
 *       properties:
 *         token:
 *           type: string
 *         new_password:
 *           type: string
 *
 *     ChangePasswordRequest:
 *       type: object
 *       required:
 *         - current_password
 *         - new_password
 *       properties:
 *         current_password:
 *           type: string
 *         new_password:
 *           type: string
 *
 *     AdminResetRequest:
 *       type: object
 *       required:
 *         - user_id
 *       properties:
 *         user_id:
 *           type: string
 *         default_password:
 *           type: string
 *
 *     UpdateProfileRequest:
 *       type: object
 *       properties:
 *         first_name:
 *           type: string
 *         last_name:
 *           type: string
 *         phone:
 *           type: string
 */

// ================= MIDDLEWARE =================

const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'Missing authorization header' });

  const token = authHeader.split(' ')[1];
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token' });
    req.user = user;
    next();
  });
};

const authorizeAdmin = (req, res, next) => {
  if (!['super_admin', 'client_admin'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Insufficient permissions' });
  }
  next();
};

// ================= AUTH ROUTES =================

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RegisterRequest'
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Validation error
 *       409:
 *         description: Email already exists
 */
router.post('/register', async (req, res) => {
  try {
    const { email, password, first_name, last_name, phone, tenant_id } = req.body;

    // Validation
    if (!email || !password || !first_name || !last_name) {
      return res.status(400).json({ success: false, error: 'Required fields missing' });
    }

    // Check if user exists
    const existingUser = await User.getByEmail(email);
    if (existingUser) {
      return res.status(409).json({ success: false, error: 'Email already exists' });
    }

    // Get tenant
    let finalTenantId = tenant_id;
    if (!finalTenantId) {
      const tenants = await Tenant.getAll({ status: 'active' });
      if (tenants.length === 0) {
        return res.status(500).json({ success: false, error: 'No tenant available' });
      }
      finalTenantId = tenants[0].id;
    }

    // Hash password
    const password_hash = await bcrypt.hash(password, 10);

    // Create user
    const newUser = await User.create({
      email,
      password_hash,
      first_name,
      last_name,
      phone: phone || null,
      tenant_id: finalTenantId,
      role: 'consumer',
    });

    // Send welcome email
    try {
      await mailer.sendWelcomeEmail(
        newUser.email,
        `${newUser.first_name || 'User'}`
      );
    } catch (emailErr) {
      console.error('Welcome email failed:', emailErr);
      // Don't block registration if email fails
    }

    res.status(201).json({
      success: true,
      data: {
        id: newUser.id,
        email: newUser.email,
        first_name: newUser.first_name,
        last_name: newUser.last_name,
        role: newUser.role,
        tenant_id: newUser.tenant_id,
        created_at: newUser.created_at,
      },
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ success: false, error: 'Registration failed' });
  }
});

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login with email or phone
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoginRequest'
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', async (req, res) => {
  try {
    const { identifier, password } = req.body;
    if (!identifier || !password)
      return res.status(400).json({ success: false, error: 'Identifier and password required' });

    const user = await User.getByIdentifier(identifier);
    if (!user || user.deleted_at)
      return res.status(401).json({ success: false, error: 'Invalid credentials' });

    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatch)
      return res.status(401).json({ success: false, error: 'Invalid credentials' });

    if (user.status !== 'active')
      return res.status(401).json({ success: false, error: 'Account is not active' });

    const token = jwt.sign(
      {
        user_id: user.id,
        email: user.email,
        role: user.role,
        tenant_id: user.tenant_id,
        name: `${user.first_name} ${user.last_name}`.trim()
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const refreshToken = crypto.randomBytes(40).toString('hex');
    await User.update(user.id, { 
      refresh_token: refreshToken,
      last_login_at: new Date() 
    });

    res.json({
      success: true,
      token,
      refresh_token: refreshToken,
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        tenant_id: user.tenant_id
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, error: 'Login failed' });
  }
});

/**
 * @swagger
 * /auth/refresh:
 *   post:
 *     summary: Refresh access token
 *     tags: [Auth]
 */
router.post('/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token)
      return res.status(400).json({ success: false, error: 'Refresh token required' });

    const user = await User.getByRefreshToken(refresh_token);
    if (!user || user.deleted_at)
      return res.status(401).json({ success: false, error: 'Invalid refresh token' });

    const token = jwt.sign(
      { 
        user_id: user.id, 
        email: user.email,
        role: user.role, 
        tenant_id: user.tenant_id 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({ success: true, token });
  } catch (err) {
    console.error('Refresh error:', err);
    res.status(500).json({ success: false, error: 'Refresh failed' });
  }
});

/**
 * @swagger
 * /auth/forgot-password:
 *   post:
 *     summary: Request password reset
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ForgotPasswordRequest'
 *     responses:
 *       200:
 *         description: Reset email sent (if account exists)
 */
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, error: 'Email required' });
    }

    const user = await User.getByEmail(email);
    
    // Always return success even if user doesn't exist (security)
    if (!user || user.deleted_at) {
      return res.json({ 
        success: true, 
        message: 'If an account exists with this email, you will receive a password reset link.' 
      });
    }

    // Generate reset token (expires in 1 hour)
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetExpires = new Date(Date.now() + 3600000); // 1 hour

    await User.update(user.id, {
      password_reset_token: resetToken,
      password_reset_expires: resetExpires
    });

    // Send email with reset link
    const emailResult = await mailer.sendPasswordResetEmail(
      user.email,
      resetToken,
      `${user.first_name || 'User'}`
    );

    if (!emailResult.success) {
      console.error('Failed to send reset email:', emailResult.error);
      // Still return success to user (security), but log the error
    }

    res.json({ 
      success: true, 
      message: 'If an account exists with this email, you will receive a password reset link.' 
    });
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ success: false, error: 'Request failed' });
  }
});

/**
 * @swagger
 * /auth/reset-password:
 *   post:
 *     summary: Reset password with token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ResetPasswordRequest'
 *     responses:
 *       200:
 *         description: Password reset successful
 *       400:
 *         description: Invalid or expired token
 */
router.post('/reset-password', async (req, res) => {
  try {
    const { token, new_password } = req.body;

    if (!token || !new_password) {
      return res.status(400).json({ success: false, error: 'Token and new password required' });
    }

    if (new_password.length < 8) {
      return res.status(400).json({ success: false, error: 'Password must be at least 8 characters' });
    }

    const user = await User.getByResetToken(token);
    
    if (!user || user.deleted_at) {
      return res.status(400).json({ success: false, error: 'Invalid or expired token' });
    }

    // Check if token expired
    if (user.password_reset_expires && new Date(user.password_reset_expires) < new Date()) {
      return res.status(400).json({ success: false, error: 'Token expired' });
    }

    // Hash new password
    const password_hash = await bcrypt.hash(new_password, 10);

    await User.update(user.id, {
      password_hash,
      password_reset_token: null,
      password_reset_expires: null
    });

    // Send confirmation email
    try {
      await mailer.sendPasswordChangedEmail(
        user.email,
        `${user.first_name || 'User'}`
      );
    } catch (emailErr) {
      console.error('Password change email failed:', emailErr);
    }

    res.json({ success: true, message: 'Password reset successful' });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ success: false, error: 'Reset failed' });
  }
});

/**
 * @swagger
 * /auth/change-password:
 *   put:
 *     summary: Change password
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ChangePasswordRequest'
 */
router.put('/change-password', authenticateJWT, async (req, res) => {
  try {
    const { current_password, new_password } = req.body;

    if (!current_password || !new_password) {
      return res.status(400).json({ success: false, error: 'Current and new password required' });
    }

    if (new_password.length < 8) {
      return res.status(400).json({ success: false, error: 'Password must be at least 8 characters' });
    }

    const user = await User.getById(req.user.user_id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const match = await bcrypt.compare(current_password, user.password_hash);
    if (!match) return res.status(401).json({ error: 'Incorrect password' });

    const password_hash = await bcrypt.hash(new_password, 10);
    await User.update(user.id, { password_hash });

    // Send confirmation email
    try {
      await mailer.sendPasswordChangedEmail(
        user.email,
        `${user.first_name || 'User'}`
      );
    } catch (emailErr) {
      console.error('Password change email failed:', emailErr);
    }

    res.json({ success: true, message: 'Password changed successfully' });
  } catch (err) {
    console.error('Change password error:', err);
    res.status(500).json({ error: 'Change failed' });
  }
});

/**
 * @swagger
 * /auth/profile:
 *   put:
 *     summary: Update profile
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdateProfileRequest'
 */
router.put('/profile', authenticateJWT, async (req, res) => {
  try {
    const { first_name, last_name, phone } = req.body;

    const updatedUser = await User.update(req.user.user_id, {
      first_name,
      last_name,
      phone
    });

    res.json({ 
      success: true, 
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        first_name: updatedUser.first_name,
        last_name: updatedUser.last_name,
        phone: updatedUser.phone,
        role: updatedUser.role
      }
    });
  } catch (err) {
    console.error('Profile update error:', err);
    res.status(500).json({ error: 'Update failed' });
  }
});

// ================= ADMIN ROUTES =================

/**
 * @swagger
 * /auth/admin/reset-password:
 *   post:
 *     summary: Admin reset user password
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/AdminResetRequest'
 */
router.post('/admin/reset-password', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { user_id, default_password } = req.body;

    if (!user_id) {
      return res.status(400).json({ success: false, error: 'User ID required' });
    }

    const user = await User.getById(user_id);
    if (!user || user.deleted_at) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const newPassword = default_password || 'Welcome123!';
    const password_hash = await bcrypt.hash(newPassword, 10);

    await User.update(user_id, { 
      password_hash,
      password_reset_token: null,
      password_reset_expires: null,
      status: 'active'
    });

    // Send notification email
    try {
      await mailer.sendPasswordChangedEmail(
        user.email,
        `${user.first_name || 'User'}`
      );
    } catch (emailErr) {
      console.error('Password reset notification email failed:', emailErr);
    }

    res.json({ 
      success: true, 
      message: 'Password reset successfully',
      temporary_password: default_password ? undefined : newPassword
    });
  } catch (err) {
    console.error('Admin reset password error:', err);
    res.status(500).json({ error: 'Reset failed' });
  }
});

/**
 * @swagger
 * /auth/admin/users/{id}:
 *   put:
 *     summary: Admin update user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.put('/admin/users/:id', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { first_name, last_name, email, phone, role, status } = req.body;

    const user = await User.getById(id);
    if (!user || user.deleted_at) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    // Check email uniqueness
    if (email && email !== user.email) {
      const existingUser = await User.getByEmail(email);
      if (existingUser) {
        return res.status(400).json({ success: false, error: 'Email already in use' });
      }
    }

    const updatedUser = await User.update(id, {
      first_name,
      last_name,
      email,
      phone,
      role,
      status,
      updated_by: req.user.user_id
    });

    res.json({ success: true, user: updatedUser });
  } catch (err) {
    console.error('Admin update error:', err);
    res.status(500).json({ error: 'Update failed' });
  }
});

/**
 * @swagger
 * /auth/admin/users/{id}:
 *   delete:
 *     summary: Soft delete user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/admin/users/:id', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    if (id === req.user.user_id) {
      return res.status(400).json({ success: false, error: 'Cannot delete your own account' });
    }

    const user = await User.getById(id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    await User.softDelete(id, req.user.user_id);

    res.json({ success: true, message: 'User deactivated successfully' });
  } catch (err) {
    console.error('Soft delete error:', err);
    res.status(500).json({ error: 'Delete failed' });
  }
});

/**
 * @swagger
 * /auth/admin/users/{id}/restore:
 *   post:
 *     summary: Restore soft-deleted user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.post('/admin/users/:id/restore', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    await User.restore(id);
    res.json({ success: true, message: 'User restored successfully' });
  } catch (err) {
    console.error('Restore error:', err);
    res.status(500).json({ error: 'Restore failed' });
  }
});

module.exports = router;