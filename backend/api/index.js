const app = require('../src/app');
const mongoose = require('mongoose');

// Connect to MongoDB
const connectDB = async () => {
  try {
    const MONGO_URL = process.env.MONGO_URL;
    
    if (!MONGO_URL) {
      console.error('❌ MONGO_URL is not defined in environment variables.');
      return;
    }

    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    
    console.log('✅ Connected to MongoDB');
  } catch (err) {
    console.error('Failed to connect to MongoDB:', err);
  }
};

// Connect to database
connectDB();

// Export the Express app for Vercel
module.exports = app;
