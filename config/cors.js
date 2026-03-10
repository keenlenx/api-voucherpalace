// config/cors.js
require('dotenv').config();

const isProduction = process.env.NODE_ENV === 'production';
const port = process.env.PORT || 3006;

// Helper function to check if origin matches wildcard patterns
const isOriginAllowed = (origin) => {
  if (!origin) return true; // Allow non-browser requests

  // Allow all localhost variants
  if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
    return true;
  }

  // Allow all 192.168.*.* IPs
  const ipMatch = origin.match(/^https?:\/\/([^:]+)/);
  if (ipMatch) {
    const host = ipMatch[1];
    if (host.startsWith('192.168.')) {
      return true;
    }
  }

  // Allow all *.agiza.co.ke domains
  if (origin.includes('.agiza.co.ke')) {
    return true;
  }

  // Allow Docker service names (for internal communication)
  const dockerServices = [
    'http://api:3006',
    'http://backend:3006',
    'http://voucher-api:3006',
    'http://voucher-backend:3006'
  ];
  if (dockerServices.some(service => origin.startsWith(service))) {
    return true;
  }

  // Explicit allowed origins
  const allowedOrigins = [
    // Production domains
    'https://voucherpalace.com',
    'https://app.voucherpalace.com',
    'https://admin.voucherpalace.com',
    'https://voucherapp.agiza.co.ke',
    'https://vouchers.agiza.co.ke',
    'https://api.voucherpalace.com',
    
    // Development domains
    `http://localhost:${port}`,
    `http://localhost:3000`,
    `http://localhost:3001`,
    `http://localhost:3002`,
    `http://localhost:3003`,
    `http://localhost:3004`,
    `http://localhost:3005`,
    `http://localhost:3006`,
    `http://localhost:3007`,
    `http://localhost:3008`,
    `http://localhost:3009`,
    `http://localhost:8080`,
    `http://127.0.0.1:3000`,
    `http://127.0.0.1:3006`,
    
    // Docker service names
    'http://api:3006',
    'http://backend:3006',
    'http://voucher-api:3006',
    'http://voucher-backend:3006',
    'http://nginx:80',
    'http://nginx:3006',
    
    // Network IPs (common ranges)
    'http://192.168.0.100:3000',
    'http://192.168.0.100:3006',
    'http://192.168.1.100:3000',
    'http://192.168.1.100:3006',
    'http://192.168.1.10:3000',
    'http://192.168.1.10:3006',
    'http://192.168.1.20:3000',
    'http://192.168.1.20:3006'
  ];

  return allowedOrigins.includes(origin);
};

const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps, curl, Postman)
    if (!origin) {
      return callback(null, true);
    }

    // Check if origin is allowed
    if (isOriginAllowed(origin)) {
      callback(null, true);
    } else {
      console.warn(`❌ CORS blocked for origin: ${origin}`);
      callback(new Error(`CORS not allowed for origin: ${origin}`));
    }
  },
  
  // Allow credentials (cookies, authorization headers)
  credentials: true,
  
  // Set which HTTP methods are allowed
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD'],
  
  // Set which headers can be used in requests
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'Accept',
    'Origin',
    'X-Forwarded-For',
    'X-Real-IP'
  ],
  
  // Headers that clients can access
  exposedHeaders: ['Content-Range', 'X-Content-Range', 'Content-Length'],
  
  // Cache preflight requests for 24 hours
  maxAge: 86400,
  
  // Set preflight response status
  optionsSuccessStatus: 200
};

// Log CORS configuration on startup
console.log('\n🔒 CORS Configuration:');
console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
console.log(`   Allow localhost: ✅`);
console.log(`   Allow 192.168.*.*: ✅`);
console.log(`   Allow *.agiza.co.ke: ✅`);
console.log(`   Allow Docker services: ✅`);
console.log(`   Credentials: ${corsOptions.credentials ? '✅' : '❌'}`);
console.log('');

module.exports = corsOptions;