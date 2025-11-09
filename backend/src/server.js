// const app = require('./app');
// const mongoose = require('mongoose');
// require('dotenv').config();

// const PORT = process.env.PORT || 5500;
// const MONGO_URL = process.env.MONGO_URL;

// mongoose
//   .connect(MONGO_URL, {
//     connectTimeoutMS: 30000, // 30 seconds
//     socketTimeoutMS: 45000, // 45 seconds
//   })
//   .then(() => {
//     console.log('Connected to MongoDB');
//     app.listen(PORT, () => {
//       console.log(`Server running on port ${PORT}`);
//     });
//   })
//   .catch((err) => {
//     console.error('Failed to connect to MongoDB', err);
//     process.exit(1);
//   });

const app = require('./app');
const mongoose = require('mongoose');
const envConfig = require('./config/env.config');
const logger = require('./utils/logger');

const PORT = envConfig.PORT;
const MONGO_URL = envConfig.MONGO_URL;

// MongoDB Connection with optimized settings
const connectDB = async () => {
  try {
    const connectionOptions = {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      serverSelectionTimeoutMS: 30000,
      // Connection pooling options
      maxPoolSize: 10, // Maximum number of connections in the pool
      minPoolSize: 2, // Minimum number of connections in the pool
      maxIdleTimeMS: 30000, // Close connections after 30 seconds of inactivity
      // Retry options
      retryWrites: true,
      retryReads: true,
    };

    await mongoose.connect(MONGO_URL, connectionOptions);
    
    logger.info('✅ Connected to MongoDB', {
      database: mongoose.connection.name,
      host: mongoose.connection.host,
    });

    // Handle connection events
    mongoose.connection.on('error', (err) => {
      logger.error('MongoDB connection error', err);
    });

    mongoose.connection.on('disconnected', () => {
      logger.warn('MongoDB disconnected. Attempting to reconnect...');
    });

    mongoose.connection.on('reconnected', () => {
      logger.info('MongoDB reconnected successfully');
    });

    // Graceful shutdown
    process.on('SIGINT', async () => {
      await mongoose.connection.close();
      logger.info('MongoDB connection closed due to app termination');
      process.exit(0);
    });

  } catch (err) {
    logger.error('Failed to connect to MongoDB', err);
    process.exit(1);
  }
};

// Start server
const startServer = async () => {
  try {
    await connectDB();
    
    app.listen(PORT, () => {
      logger.info(`🚀 Server running on port ${PORT}`, {
        environment: envConfig.NODE_ENV,
        nodeVersion: process.version,
      });
    });
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

startServer();

 

