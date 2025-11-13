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

// Allowed origins for CORS
const allowedOrigins = [
  'https://tailor-app-lemon.vercel.app',
  'http://localhost:8144',
  'http://localhost:3000',
  'http://127.0.0.1:8144',
  'http://127.0.0.1:3000',
];

// Vercel serverless function handler
// CRITICAL: This MUST handle CORS before Express app runs
// 🔥 FIX: Set req.path, req.originalUrl, and req.hostname before passing to Express
module.exports = (req, res) => {
  const origin = req.headers.origin;

  // CORS HEADERS — Allow immediately
  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
  } else {
    res.setHeader('Access-Control-Allow-Origin', '*');
  }

  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers'
  );

  res.setHeader(
    'Access-Control-Allow-Methods',
    'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS'
  );

  // Handle OPTIONS preflight
  if (req.method === 'OPTIONS') {
    console.log('✅ OPTIONS preflight handled at serverless function level');
    console.log('📍 Origin:', origin || 'no origin');
    return res.status(200).end();
  }

  // 🔥 FIX MISSING EXPRESS FIELDS
  // Vercel doesn't provide these fields, but Express requires them
  req.originalUrl = req.originalUrl || req.url;
  req.path = req.path || req.url.split('?')[0];
  req.hostname = req.headers.host;

  // Debug Logs
  console.log('📥 Incoming:', req.method, req.url);
  console.log('📍 req.path:', req.path);
  console.log('📍 req.originalUrl:', req.originalUrl);

  // Ensure CORS remains even after Express modifies response
  const _end = res.end;
  res.end = function (...args) {
    if (!res.getHeader('Access-Control-Allow-Origin')) {
      res.setHeader('Access-Control-Allow-Origin', origin || '*');
    }
    return _end.apply(this, args);
  };

  return app(req, res);
};
