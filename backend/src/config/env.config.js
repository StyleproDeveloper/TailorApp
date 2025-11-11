require('dotenv').config();

/**
 * Environment Configuration
 * Validates and exports environment variables
 */
const requiredEnvVars = ['MONGO_URL'];

const validateEnv = () => {
  const missing = requiredEnvVars.filter((varName) => !process.env[varName]);
  
  if (missing.length > 0) {
    console.error(`❌ Missing required environment variables: ${missing.join(', ')}`);
    process.exit(1);
  }
  
  // Validate MongoDB URL format
  if (process.env.MONGO_URL && !process.env.MONGO_URL.startsWith('mongodb')) {
    console.error('❌ Invalid MONGO_URL format. Must start with "mongodb"');
    process.exit(1);
  }
};

validateEnv();

module.exports = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: process.env.PORT || 5500,
  MONGO_URL: process.env.MONGO_URL,
  // Add other environment variables as needed
  FRONTEND_URL: process.env.FRONTEND_URL || 'http://localhost:8144',
  JWT_SECRET: process.env.JWT_SECRET || 'your-secret-key-change-in-production',
  // Rate limiting: More lenient in development, stricter in production
  RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 
    (process.env.NODE_ENV === 'production' ? 15 * 60 * 1000 : 60 * 1000), // 15 min prod, 1 min dev
  RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 
    (process.env.NODE_ENV === 'production' ? 100 : 1000), // 100 prod, 1000 dev
};

