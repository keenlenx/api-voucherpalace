// app.js
require('dotenv').config();
const express = require('express');
const swaggerUi = require('swagger-ui-express');
const cors = require('cors');

// Import configurations
const corsOptions = require('./config/cors');
const { swaggerDocs, swaggerUiOptions } = require('./swagger/swagger');
const db = require('./database/dbService'); // Your simple dbService
const { authenticateJWT } = require('./middleware/Auth');

const path = require('path');
const app = express();
const port = process.env.PORT;

// Make db available to routes
app.use((req, res, next) => {
  req.db = db;
  next();
});

// Middleware
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Public routes
app.use(express.static(path.join(__dirname, 'web')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'web', 'index.html'));
});
app.get('/user', (req, res) => {
  res.sendFile(path.join(__dirname, 'web', 'user.html'));
});
app.get('/cafe', (req, res) => {
  res.sendFile(path.join(__dirname, 'web', 'cafe.html'));
});
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs, swaggerUiOptions));

app.get('/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.status(200).json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (err) {
    // Return 503 when database is down
    res.status(503).json({ 
      status: 'unhealthy', 
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: err.message
    });
  }
});

app.get('/health/db', async (req, res) => {
  try {
    await req.db.query('SELECT 1');
    res.json({ status: 'healthy', database: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', database: 'disconnected', error: err.message });
  }
});

app.use('/auth', require('./routes/auth'));

// Protected routes
app.use('/tenants', authenticateJWT, require('./routes/tenants'));
app.use('/users', authenticateJWT, require('./routes/users'));
app.use('/merchants', authenticateJWT, require('./routes/merchants'));
app.use('/voucher_templates', authenticateJWT, require('./routes/voucher_templates'));
app.use('/vouchers', authenticateJWT, require('./routes/vouchers'));
app.use('/redemptions', authenticateJWT, require('./routes/redemptions'));
app.use('/purchase_orders', authenticateJWT, require('./routes/purchase_orders'));
app.use('/settlements', authenticateJWT, require('./routes/settlements'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Get local IP address for display
function getLocalIP() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Skip internal and non-IPv4 addresses
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return '0.0.0.0';
}

const localIP = getLocalIP();

// Start server - bind to 0.0.0.0 to accept connections from all network interfaces
const server = app.listen(port, '0.0.0.0', () => {
  console.log('\n' + '='.repeat(60));
  console.log(`🚀 Server running on port ${port}`);
  console.log(`   Local:   http://localhost:${port}`);
  console.log(`   Network: http://${localIP}:${port}`);
  console.log(`   Mobile:  http://${localIP}:${port} (use this on your phone)`);
  console.log('-' .repeat(60));
  console.log(`📚 Swagger:  http://localhost:${port}/api-docs`);
  console.log(`📱 Mobile Swagger: http://${localIP}:${port}/api-docs`);
  console.log(`💓 Health:   http://localhost:${port}/health`);
  console.log('-' .repeat(60));
  console.log(`📦 Database: ${process.env.DATABASE_NAME || 'connected'}`);
  console.log('='.repeat(60) + '\n');
});

// Optional: Also log the database connection (sanitized)
if (process.env.DATABASE_URL) {
  const dbUrl = new URL(process.env.DATABASE_URL);
  console.log(`📊 Database: ${dbUrl.hostname}/${dbUrl.pathname.split('/')[1]}`);
}
// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('\n📦 SIGTERM received: shutting down gracefully...');
  server.close(() => {
    db.pool.end().then(() => {
      console.log('✅ Database connections closed');
      process.exit(0);
    }).catch(err => {
      console.error('Error closing database:', err);
      process.exit(1);
    });
  });
});

process.on('SIGINT', () => {
  console.log('\n📦 SIGINT received: shutting down gracefully...');
  server.close(() => {
    db.pool.end().then(() => {
      console.log('✅ Database connections closed');
      process.exit(0);
    }).catch(err => {
      console.error('Error closing database:', err);
      process.exit(1);
    });
  });
});