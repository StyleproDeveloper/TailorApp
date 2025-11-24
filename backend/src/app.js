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
const PaymentRoutes = require('./routes/PaymentRoutes');
const GalleryRoutes = require('./routes/GalleryRoutes');
const swaggerConfig = require('./config/swagger');
const envConfig = require('./config/env.config');
const logger = require('./utils/logger');
const path = require('path');

const app = express();

// Trust proxy - REQUIRED for AWS Elastic Beanstalk load balancer
// This allows Express to correctly identify client IPs from X-Forwarded-For headers
app.set('trust proxy', true);

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

// Handle OPTIONS preflight requests FIRST - before any other middleware
// CRITICAL: This must be FIRST to handle CORS preflight
app.options('*', (req, res) => {
  logger.info('CORS Preflight Request', { 
    origin: req.headers.origin,
    method: req.method,
    url: req.url 
  });
  
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Access-Control-Allow-Credentials', 'false');
  res.status(200).end();
  
  logger.info('CORS Preflight Response Sent');
});

// Security Middleware - DISABLE helmet CORS blocking
app.use(helmet({
  contentSecurityPolicy: false, // Disable CSP for API (can be enabled if needed)
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: false, // Allow cross-origin resources
}));

// CORS Configuration - Allow ALL origins to fix CORS issues completely
// This is the most permissive configuration - allows requests from any origin
const corsOptions = {
  origin: '*', // Explicitly use wildcard for maximum compatibility
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin', 'Access-Control-Request-Method', 'Access-Control-Request-Headers'],
  credentials: false, // Set to false when using wildcard origin (*)
  optionsSuccessStatus: 200,
  preflightContinue: false,
  maxAge: 86400, // Cache preflight requests for 24 hours
};

app.use(cors(corsOptions));

// Additional explicit CORS headers as backup (in case cors middleware doesn't work)
app.use((req, res, next) => {
  // Set CORS headers explicitly - use wildcard for maximum compatibility
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
  res.setHeader('Access-Control-Max-Age', '86400');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  next();
});

// Rate Limiting - More lenient in development
// Use X-Forwarded-For header to get real client IP (important for CloudFront)
const limiter = rateLimit({
  windowMs: envConfig.RATE_LIMIT_WINDOW_MS,
  max: envConfig.RATE_LIMIT_MAX_REQUESTS,
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Get real client IP from X-Forwarded-For header (CloudFront forwards this)
  keyGenerator: (req) => {
    // CloudFront and load balancers forward the real client IP in X-Forwarded-For
    const forwarded = req.headers['x-forwarded-for'];
    if (forwarded) {
      // X-Forwarded-For can contain multiple IPs, take the first one (original client)
      const clientIp = forwarded.split(',')[0].trim();
      return clientIp;
    }
    // Fallback to direct connection IP
    return req.ip || req.connection.remoteAddress || req.socket.remoteAddress;
  },
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

// Dedicated health check endpoint for AWS/Docker
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
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
app.use('/payments', PaymentRoutes);
app.use('/gallery', GalleryRoutes);

// Handle 404 (Not Found)
app.use(notFound);

// Error handling middleware
app.use(errorHandler);

module.exports = app;
