const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const { notFound, errorHandler } = require('./utils/error.handlers');
const shopRoutes = require('./routes/ShopRoutes');
const customerRoutes = require('./routes/CustomerRoutes');
const userRoutes = require('./routes/UserRoutes');
const roleRoutes = require('./routes/RoleRoutes');
const expenseRoutes = require('./routes/ExpenseRoutes');
const dressTypeRoutes = require('./routes/DressTypeRoutes');
const measurementRoutes = require('./routes/MeasurementRoutes');
const authRoutes = require('./routes/AuthRoutes');
const dressTypeMeasurementRoutes = require('./routes/DressTypeMeasurementRoutes');
const dressPatternRoutes = require('./routes/DressPatternRoutes');
const dressTypeDressPatternRoutes = require('./routes/DressTypeDressPatternRoutes');
const OrderDressTypeMeaPat = require('../src/routes/OrderDressTypeMeaPatternRoutes');
const BillingTermRoutes = require('./routes/BillingTermRoutes');
const OrderRoutes = require('./routes/OrderRoutes');
const OrderMediaRoutes = require('./routes/OrderMediaRoutes');
const UserBarnchRoutes = require('./routes/UserBranchRoutes');
const swaggerConfig = require('./config/swagger');
const envConfig = require('./config/env.config');
const logger = require('./utils/logger');
const path = require('path');

const app = express();
app.use(
  '/api-docs',
  swaggerConfig.swaggerUi.serve,
  (req, res, next) => {
    if (req?.path?.endsWith('/') && req?.path !== '/') {
      return res?.redirect(301, req?.baseUrl);
    }
    next();
  },
  swaggerConfig.swaggerUi.setup(swaggerConfig.specs)
);

// Security Middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable CSP for API (can be enabled if needed)
  crossOriginEmbedderPolicy: false,
}));

// CORS Configuration - Very permissive for production to fix CORS issues
const corsOptions = {
  origin: function (origin, callback) {
    // Always allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) {
      return callback(null, true);
    }
    
    // Development origins
    const devOrigins = ['http://localhost:8144', 'http://localhost:3000', 'http://127.0.0.1:8144'];
    
    // Check if origin is a Vercel URL (both preview and production)
    const isVercelUrl = origin.includes('.vercel.app') || origin.includes('vercel.app');
    
    // Check if we're in production (check both envConfig and process.env)
    const isProduction = envConfig.NODE_ENV === 'production' || process.env.NODE_ENV === 'production';
    
    // Always allow Vercel URLs (preview and production)
    if (isVercelUrl) {
      logger.debug('CORS allowing Vercel origin', { origin, nodeEnv: process.env.NODE_ENV, envConfig: envConfig.NODE_ENV });
      return callback(null, true);
    }
    
    // In production: Allow ALL origins (very permissive to fix CORS issues)
    if (isProduction) {
      logger.debug('CORS allowing origin in production', { origin, nodeEnv: process.env.NODE_ENV, envConfig: envConfig.NODE_ENV });
      return callback(null, true);
    }
    
    // In development: Only allow localhost origins
    if (devOrigins.includes(origin)) {
      logger.debug('CORS allowing dev origin', { origin });
      return callback(null, true);
    }
    
    // Log blocked origin (shouldn't happen in production or for Vercel URLs)
    logger.warn('CORS blocked origin', { 
      origin, 
      env: envConfig.NODE_ENV,
      nodeEnv: process.env.NODE_ENV,
      isVercelUrl,
      isProduction
    });
    callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  credentials: true,
  optionsSuccessStatus: 200,
  preflightContinue: false,
};

app.use(cors(corsOptions));

// Rate Limiting - More lenient in development
const limiter = rateLimit({
  windowMs: envConfig.RATE_LIMIT_WINDOW_MS,
  max: envConfig.RATE_LIMIT_MAX_REQUESTS,
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting in development for localhost
  skip: (req) => {
    // Skip rate limiting for localhost in development
    if (envConfig.NODE_ENV === 'development') {
      const ip = req.ip || req.connection.remoteAddress;
      return ip === '127.0.0.1' || ip === '::1' || ip === '::ffff:127.0.0.1' || req.hostname === 'localhost';
    }
    return false;
  },
});

// Only apply rate limiting in production or for non-localhost requests
if (envConfig.NODE_ENV === 'production') {
  app.use('/api/', limiter); // Apply to all /api/ routes
  app.use(limiter); // Apply globally as fallback
} else {
  // In development, only apply to non-localhost IPs (if any)
  app.use((req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const isLocalhost = ip === '127.0.0.1' || ip === '::1' || ip === '::ffff:127.0.0.1' || req.hostname === 'localhost';
    if (!isLocalhost) {
      return limiter(req, res, next);
    }
    next();
  });
}

// Body Parsing
app.use(bodyParser.json({ limit: '10mb' })); // Limit payload size
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Security: Sanitize MongoDB queries
app.use(mongoSanitize());

// Serve static files (uploads)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Request Logging (in development)
if (envConfig.NODE_ENV !== 'production') {
  app.use((req, res, next) => {
    logger.debug(`${req.method} ${req.path}`, {
      query: req.query,
      body: req.method !== 'GET' ? req.body : undefined,
    });
    next();
  });
}

// Serve Swagger documentation
// app.use(
//   '/api-docs',
//   swaggerConfig.swaggerUi.serve,
//   swaggerConfig.swaggerUi.setup(swaggerConfig.specs)
// );

// app.use(helmet());

// Health check route
app.get('/', (req, res) => {
  res.json({
    success: true,
    status: 200,
    message: 'Tailor App Backend API is running!',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Routes
app.use('/shops', shopRoutes);
app.use('/customer', customerRoutes);
app.use('/users', userRoutes);
app.use('/roles', roleRoutes);
app.use('/expense', expenseRoutes);
app.use('/dress-type', dressTypeRoutes);
app.use('/measurement', measurementRoutes);
app.use('/auth', authRoutes);
app.use('/dresstype-measurement', dressTypeMeasurementRoutes);
app.use('/dress-pattern', dressPatternRoutes);
app.use('/dress-type-pattern', dressTypeDressPatternRoutes);
app.use('/order-dressType-mea', OrderDressTypeMeaPat);
app.use('/billing-term', BillingTermRoutes);
app.use('/orders', OrderRoutes);
app.use('/order-media', OrderMediaRoutes);
app.use('/user-branch', UserBarnchRoutes);

// Handle 404 (Not Found)
app.use(notFound);

// Error handling middleware
app.use(errorHandler);

module.exports = app;
