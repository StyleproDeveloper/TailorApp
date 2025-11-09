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
const UserBarnchRoutes = require('./routes/UserBranchRoutes');
const swaggerConfig = require('./config/swagger');
const envConfig = require('./config/env.config');
const logger = require('./utils/logger');

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

// CORS Configuration
const corsOptions = {
  origin: envConfig.NODE_ENV === 'production' 
    ? envConfig.FRONTEND_URL.split(',').map(url => url.trim()) // Support multiple origins
    : ['http://localhost:8144', 'http://localhost:3000', 'http://127.0.0.1:8144'], // Development origins
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
  allowedHeaders: 'Content-Type, Authorization, X-Requested-With',
  credentials: true,
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));

// Rate Limiting
const limiter = rateLimit({
  windowMs: envConfig.RATE_LIMIT_WINDOW_MS,
  max: envConfig.RATE_LIMIT_MAX_REQUESTS,
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter); // Apply to all /api/ routes
app.use(limiter); // Apply globally as fallback

// Body Parsing
app.use(bodyParser.json({ limit: '10mb' })); // Limit payload size
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Security: Sanitize MongoDB queries
app.use(mongoSanitize());

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
app.use('/user-branch', UserBarnchRoutes);

// Handle 404 (Not Found)
app.use(notFound);

// Error handling middleware
app.use(errorHandler);

module.exports = app;
