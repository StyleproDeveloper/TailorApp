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
    // Don't exit in serverless environment - let it fail gracefully
    if (process.env.VERCEL || process.env.AWS_LAMBDA_FUNCTION_NAME) {
      console.warn('⚠️ Running in serverless environment - app will start but may fail on API calls');
      return;
    }
    process.exit(1);
  }
  
  // Validate MongoDB URL format
  if (process.env.MONGO_URL && !process.env.MONGO_URL.startsWith('mongodb')) {
    console.error('❌ Invalid MONGO_URL format. Must start with "mongodb"');
    // Don't exit in serverless environment
    if (process.env.VERCEL || process.env.AWS_LAMBDA_FUNCTION_NAME) {
      console.warn('⚠️ Invalid MONGO_URL - app will start but may fail on API calls');
      return;
    }
    process.exit(1);
  }
};

validateEnv();

module.exports = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: process.env.PORT || 8080, // Default to 8080 for Elastic Beanstalk compatibility
  MONGO_URL: process.env.MONGO_URL,
  // Add other environment variables as needed
  FRONTEND_URL: process.env.FRONTEND_URL || 'http://localhost:8144',
  JWT_SECRET: process.env.JWT_SECRET || 'your-secret-key-change-in-production',
  // Rate limiting: More lenient in development, reasonable limits in production
  // Increased production limits to handle CloudFront and multiple users
  RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 
    (process.env.NODE_ENV === 'production' ? 15 * 60 * 1000 : 60 * 1000), // 15 min prod, 1 min dev
  RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 
    (process.env.NODE_ENV === 'production' ? 1000 : 1000), // 1000 prod (increased from 100), 1000 dev
};

