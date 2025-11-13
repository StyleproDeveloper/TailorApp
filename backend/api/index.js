const app = require('../src/app');
const mongoose = require('mongoose');

// MongoDB connection state
let isConnected = false;

// Connect to MongoDB (optimized for serverless)
const connectDB = async () => {
  // If already connected, return
  if (isConnected && mongoose.connection.readyState === 1) {
    console.log('✅ Using existing MongoDB connection');
    return;
  }

  try {
    const MONGO_URL = process.env.MONGO_URL;
    
    if (!MONGO_URL) {
      console.error('❌ MONGO_URL is not defined in environment variables.');
      console.error('Please set MONGO_URL in Vercel project settings → Environment Variables');
      // Don't throw error - let the app start but API calls will fail gracefully
      return;
    }

    // Close existing connection if any
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
    }

    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 10000, // Reduced for serverless
      socketTimeoutMS: 45000,
      serverSelectionTimeoutMS: 10000, // Reduced for serverless
      maxPoolSize: 1, // Serverless: use single connection
      minPoolSize: 1,
    });
    
    isConnected = true;
    console.log('✅ Connected to MongoDB');
    
    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error('MongoDB connection error:', err);
      isConnected = false;
    });

    mongoose.connection.on('disconnected', () => {
      console.warn('MongoDB disconnected');
      isConnected = false;
    });

  } catch (err) {
    console.error('Failed to connect to MongoDB:', err.message);
    isConnected = false;
    // Don't throw - let the function continue (will fail gracefully on API calls)
  }
};

// Connect to database (non-blocking for serverless)
connectDB().catch(err => {
  console.error('MongoDB connection initialization error:', err.message);
});

// CRITICAL: Wrap the app to handle CORS at the ABSOLUTE entry point
// This ensures CORS headers are set BEFORE any Express middleware can interfere
const handler = (req, res) => {
  // Set CORS headers IMMEDIATELY - this happens before Express even sees the request
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
  res.setHeader('Access-Control-Max-Age', '86400');
  
  // Handle OPTIONS preflight IMMEDIATELY - don't even pass to Express
  if (req.method === 'OPTIONS') {
    console.log('✅ OPTIONS preflight handled at serverless function level');
    return res.status(200).end();
  }
  
  // Pass to Express app for all other requests
  return app(req, res);
};

// Export the wrapped handler for Vercel
// This is the entry point - CORS is handled here FIRST
module.exports = handler;
