const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
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
require('dotenv').config();

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

// Middleware
app.use(
  cors({
    origin: '*', // Replace '*' with frontend domain in production
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type, Authorization',
  })
);
// app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
app.use(bodyParser.json());
app.use(express.json());
app.use(mongoSanitize());

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
