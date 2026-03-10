const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Tenant = require('../models/Tenant');

class AuthController {
  // Register a new user
  async register(req, res) {
    try {
      const { email, password, first_name, last_name, phone, tenant_id } = req.body;

      // Validation
      if (!email || !password || !first_name || !last_name) {
        return res.status(400).json({ 
          success: false, 
          error: 'Email, password, first_name, and last_name are required' 
        });
      }

      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({ success: false, error: 'Invalid email format' });
      }

      // Check if user exists
      const existingUser = await User.getByEmail(email);
      if (existingUser) {
        return res.status(409).json({ success: false, error: 'Email already exists' });
      }

      // Use provided tenant_id or get first active tenant
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

      // Create user with consumer role (default)
      const newUser = await User.create({
        email,
        password_hash,
        first_name,
        last_name,
        phone: phone || null,
        tenant_id: finalTenantId,
        role: 'consumer',
      });

      console.log('User registered successfully:', newUser.id);

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
      res.status(500).json({ 
        success: false, 
        error: 'Registration failed', 
        message: err.message 
      });
    }
  }

  // Login user
  async login(req, res) {
    try {
      const { email, password } = req.body;

      // Validation
      if (!email || !password) {
        return res.status(400).json({ success: false, error: 'Email and password required' });
      }

      // Find user by email
      const user = await User.getByEmail(email);
      console.log('Login attempt for:', email, '| User found:', !!user);

      if (!user) {
        return res.status(401).json({ success: false, error: 'Invalid credentials' });
      }

      // Verify password
      const passwordMatch = await bcrypt.compare(password, user.password_hash);
      console.log('Password verification:', passwordMatch);

      if (!passwordMatch) {
        return res.status(401).json({ success: false, error: 'Invalid credentials' });
      }

      // Check if user account is active
      if (user.status !== 'active') {
        return res.status(401).json({ success: false, error: 'Account is not active' });
      }

      // Generate JWT token
      const token = jwt.sign(
        {
          user_id: user.id,
          email: user.email,
          name: `${user.first_name} ${user.last_name}`,
          role: user.role,
          tenant_id: user.tenant_id,
          permissions: user.permissions || [], // Add permissions if you have them
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );

      // Update last_login_at timestamp
      await User.update(user.id, { last_login_at: new Date() });

      console.log('Login successful for:', email);

      res.status(200).json({
        success: true,
        token,
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          tenant_id: user.tenant_id,
        },
      });
    } catch (err) {
      console.error('Login error:', err);
      res.status(500).json({ 
        success: false, 
        error: 'Login failed', 
        message: err.message 
      });
    }
  }

  // Logout user (optional - mainly for client-side token removal)
  async logout(req, res) {
    try {
      // You can implement token blacklisting here if needed
      res.status(200).json({ 
        success: true, 
        message: 'Logged out successfully' 
      });
    } catch (err) {
      console.error('Logout error:', err);
      res.status(500).json({ 
        success: false, 
        error: 'Logout failed' 
      });
    }
  }

  // Get current user profile
  async getProfile(req, res) {
    try {
      const user = await User.getById(req.user.user_id);
      
      if (!user) {
        return res.status(404).json({ 
          success: false, 
          error: 'User not found' 
        });
      }

      res.status(200).json({
        success: true,
        data: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          tenant_id: user.tenant_id,
          phone: user.phone,
          created_at: user.created_at,
          last_login_at: user.last_login_at,
        },
      });
    } catch (err) {
      console.error('Get profile error:', err);
      res.status(500).json({ 
        success: false, 
        error: 'Failed to get profile' 
      });
    }
  }

  // Update user profile
  async updateProfile(req, res) {
    try {
      const { first_name, last_name, phone } = req.body;
      
      const updatedUser = await User.update(req.user.user_id, {
        first_name,
        last_name,
        phone,
      });

      res.status(200).json({
        success: true,
        data: {
          id: updatedUser.id,
          email: updatedUser.email,
          first_name: updatedUser.first_name,
          last_name: updatedUser.last_name,
          phone: updatedUser.phone,
        },
      });
    } catch (err) {
      console.error('Update profile error:', err);
      res.status(500).json({ 
        success: false, 
        error: 'Failed to update profile' 
      });
    }
  }

  // Change password
  async changePassword(req, res) {
    try {
      const { current_password, new_password } = req.body;
      
      const user = await User.getById(req.user.user_id);
      
      // Verify current password
      const passwordMatch = await bcrypt.compare(current_password, user.password_hash);
      
      if (!passwordMatch) {
        return res.status(401).json({ 
          success: false, 
          error: 'Current password is incorrect' 
        });
      }

      // Hash new password
      const newPasswordHash = await bcrypt.hash(new_password, 10);
      
      // Update password
      await User.update(req.user.user_id, { 
        password_hash: newPasswordHash 
      });

      res.status(200).json({ 
        success: true, 
        message: 'Password changed successfully' 
      });
    } catch (err) {
      console.error('Change password error:', err);
      res.status(500).json({ 
        success: false, 
        error: 'Failed to change password' 
      });
    }
  }
}

module.exports = new AuthController();