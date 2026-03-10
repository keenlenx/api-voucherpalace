// swagger.js
require('dotenv').config();
const swaggerJsdoc = require('swagger-jsdoc');

const port = process.env.PORT || 3005;

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Voucher Management API - Romeo Fox Alpha',
      version: '1.0.0',
      description: 'Production-ready API for managing vouchers, tenants, users, merchants, and redemptions',
      contact: {
        name: 'API Support',
        email: 'support@romeofoxalpha.com',
      },
      license: {
        name: 'Proprietary',
      },
    },
    servers: [
      {
        url: `http://localhost:${port}`,
        description: 'Development Server',
      },
      {
        url: `http://192.168.0.100:${port}`,
        description: 'Local Network Server'
      },
      {
        url: `http://voucherapp.agiza.co.ke:3006/`,
        description: 'Production Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT Authorization header using the Bearer scheme',
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
    tags: [
      { name: 'Auth', description: 'Authentication endpoints (no JWT required)' },
      { name: 'Tenants', description: 'Client companies and merchants management' },
      { name: 'Users', description: 'User management across tenants' },
      { name: 'Merchants', description: 'Merchant store locations and management' },
      { name: 'Voucher Templates', description: 'Voucher template creation and management' },
      { name: 'Vouchers', description: 'Individual issued voucher instances' },
      { name: 'Redemptions', description: 'Voucher redemption transactions and tracking' },
      { name: 'Purchase Orders', description: 'Consumer e-commerce purchases from public storefront' },
      { name: 'Settlements', description: 'Merchant payment settlements for redeemed vouchers' },
    ],
  },
  apis: ['./routes/*.js'], // Path to your route files
};

// Generate swagger specs
const swaggerDocs = swaggerJsdoc(swaggerOptions);

// UI Options
const swaggerUiOptions = {
  swaggerOptions: {
    persistAuthorization: true,
    displayOperationId: false,
    filter: true,
    showRequestHeaders: true,
    docExpansion: 'list', // 'none', 'list', 'full'
    defaultModelsExpandDepth: 3,
    defaultModelExpandDepth: 3,
  },
  customCss: `
    .topbar { display: none; }
    .swagger-ui .topbar { background-color: #1c1c1c; }
    .swagger-ui { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
    .swagger-ui .info .title { color: #1976d2; }
    .swagger-ui .btn.authorize { background-color: #1976d2; }
    .swagger-ui .btn.authorize:hover { background-color: #1565c0; }
    .swagger-ui .scheme-container { background-color: #f8f9fa; }
    .swagger-ui .opblock-tag { font-size: 18px; font-weight: 600; }
    .response-col_status { font-weight: 600; }
  `,
  customSiteTitle: 'Voucher API Documentation',
  customfavIcon: '/favicon.ico', // Optional: add your favicon
};

// Export both docs and options
module.exports = {
  swaggerDocs,
  swaggerUiOptions,
};