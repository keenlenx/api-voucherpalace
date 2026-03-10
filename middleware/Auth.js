const jwt = require('jsonwebtoken');

/**
 * Authentication Middleware
 * Verifies JWT token and attaches user to request
 */
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ 
      success: false, 
      error: 'Missing authorization header' 
    });
  }

  // Check if it's Bearer token
  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ 
      success: false, 
      error: 'Invalid authorization format. Use Bearer token' 
    });
  }

  const token = authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      error: 'Token missing' 
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(403).json({ 
          success: false, 
          error: 'Token expired',
          code: 'TOKEN_EXPIRED'
        });
      }
      if (err.name === 'JsonWebTokenError') {
        return res.status(403).json({ 
          success: false, 
          error: 'Invalid token',
          code: 'INVALID_TOKEN'
        });
      }
      return res.status(403).json({ 
        success: false, 
        error: 'Authentication failed',
        code: 'AUTH_FAILED'
      });
    }

    // Attach user info to request
    req.user = {
      id: decoded.user_id,
      email: decoded.email,
      role: decoded.role,
      tenant_id: decoded.tenant_id,
      name: decoded.name
    };
    
    next();
  });
};

/**
 * Role-based Authorization
 * @param {...string} roles - Allowed roles
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        success: false, 
        error: 'Unauthorized - Please authenticate first' 
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        success: false, 
        error: 'Forbidden - Insufficient permissions',
        required_roles: roles,
        your_role: req.user.role
      });
    }

    next();
  };
};

/**
 * Optional Authentication - doesn't fail if no token
 * Useful for public routes that can have user context if available
 */
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    
    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (!err && decoded) {
        req.user = {
          id: decoded.user_id,
          email: decoded.email,
          role: decoded.role,
          tenant_id: decoded.tenant_id,
          name: decoded.name
        };
      }
      next(); // Always continue, even if token invalid
    });
  } else {
    next(); // No token, continue as unauthenticated
  }
};

/**
 * Tenant-based Authorization
 * Ensures user belongs to the specified tenant
 */
const authorizeTenant = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false, 
      error: 'Unauthorized - Please authenticate first' 
    });
  }

  const tenantId = req.params.tenant_id || req.body.tenant_id;
  
  if (tenantId && req.user.tenant_id !== tenantId) {
    // Super admin can bypass tenant restriction
    if (req.user.role === 'super_admin') {
      return next();
    }
    
    return res.status(403).json({ 
      success: false, 
      error: 'Forbidden - You do not have access to this tenant' 
    });
  }

  next();
};

/**
 * Self or Admin Authorization
 * Allows access if user is admin OR accessing their own resource
 */
const authorizeSelfOrAdmin = (paramName = 'id') => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        success: false, 
        error: 'Unauthorized - Please authenticate first' 
      });
    }

    const targetUserId = req.params[paramName];
    
    // Allow if user is admin or accessing their own data
    if (req.user.role === 'super_admin' || 
        req.user.role === 'client_admin' || 
        req.user.id === targetUserId) {
      return next();
    }

    return res.status(403).json({ 
      success: false, 
      error: 'Forbidden - You can only access your own data' 
    });
  };
};

/**
 * Generate JWT Token
 * Helper function for creating tokens
 */
const generateToken = (user) => {
  return jwt.sign(
    {
      user_id: user.id,
      email: user.email,
      role: user.role,
      tenant_id: user.tenant_id,
      name: `${user.first_name || ''} ${user.last_name || ''}`.trim()
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRY || '24h' }
  );
};

/**
 * Verify Token
 * Helper function to verify and decode token
 */
const verifyToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return { valid: true, decoded };
  } catch (err) {
    return { 
      valid: false, 
      error: err.name === 'TokenExpiredError' ? 'expired' : 'invalid' 
    };
  }
};

module.exports = {
  authenticateJWT,
  authorize,
  optionalAuth,
  authorizeTenant,
  authorizeSelfOrAdmin,
  generateToken,
  verifyToken
};