const app = require('./src/app');
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

    mongoose.connection.on('reconnected', () => {
      console.log('✅ MongoDB reconnected');
      isConnected = true;
    });

  } catch (err) {
    console.error('Failed to connect to MongoDB:', err.message);
    isConnected = false;
  }
};

// Initialize connection
connectDB().catch(err => {
  console.error('MongoDB connection initialization error:', err.message);
});

// Export handler for Vercel serverless
module.exports = (req, res) => {
  // Set CORS headers IMMEDIATELY - before anything else
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
  res.setHeader('Access-Control-Max-Age', '86400');
  
  // Handle OPTIONS preflight request - return immediately
  if (req.method === 'OPTIONS') {
    console.log('✅ OPTIONS preflight handled at serverless function level');
    console.log('📍 Origin:', req.headers.origin || 'no origin');
    console.log('📍 Method:', req.method);
    console.log('📍 URL:', req.url);
    return res.status(200).end();
  }
  
  // Log all requests for debugging
  console.log('📥 Incoming request:', req.method, req.url);
  console.log('📍 Origin:', req.headers.origin || 'no origin');
  console.log('📍 Path:', req.path);
  console.log('📍 Original URL:', req.originalUrl);
  
  // Ensure CORS headers are set on response
  const originalEnd = res.end;
  res.end = function(...args) {
    if (!res.getHeader('Access-Control-Allow-Origin')) {
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, PUT, PATCH, POST, DELETE, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
    }
    return originalEnd.apply(this, args);
  };
  
  return app(req, res);
};

