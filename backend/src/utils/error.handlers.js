const logger = require('./logger');

const notFound = (req, res, next) => {
  const error = new Error(`Not Found: ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

const errorHandler = (err, req, res, next) => {
  let statusCode = res.statusCode === 200 ? 500 : res.statusCode;

  // If it's a CustomError, use its statusCode
  if (err instanceof CustomError && err.statusCode) {
    statusCode = err.statusCode;
  } else if (err.statusCode) {
    statusCode = err.statusCode;
  }

  // Log error for monitoring
  if (statusCode >= 500) {
    logger.error('Server Error', {
      message: err.message,
      stack: err.stack,
      path: req.originalUrl,
      method: req.method,
      statusCode,
    });
  } else {
    logger.warn('Client Error', {
      message: err.message,
      path: req.originalUrl,
      method: req.method,
      statusCode,
    });
  }

  // Handle specific error types
  if (err.name === 'ValidationError') {
    statusCode = 400;
  } else if (err.name === 'CastError') {
    statusCode = 400;
    err.message = 'Invalid ID format';
  } else if (err.name === 'MongoServerError' && err.code === 11000) {
    statusCode = 409;
    // Extract the field name from the error message
    const keyPattern = err.keyPattern || {};
    const keyValue = err.keyValue || {};
    const duplicateField = Object.keys(keyPattern)[0];
    const duplicateValue = keyValue[duplicateField];
    
    // Create a more specific error message
    if (duplicateField === 'mobile') {
      err.message = `Mobile number ${duplicateValue} is already registered. Please use a different mobile number.`;
    } else if (duplicateField === 'email') {
      err.message = `Email ${duplicateValue} is already registered. Please use a different email.`;
    } else {
      err.message = `Duplicate entry: ${duplicateField} "${duplicateValue}" already exists.`;
    }
  } else if (err.name === 'MongoServerError' && err.message && err.message.includes('already using') && err.message.includes('collections')) {
    // MongoDB Atlas collection limit exceeded
    statusCode = 507; // 507 Insufficient Storage
    err.message = 'Database collection limit exceeded. MongoDB Atlas free tier allows 500 collections. Please upgrade your MongoDB Atlas plan or contact support to clean up unused collections.';
  }

  // Prepare error response
  const errorResponse = {
    success: false,
    status: statusCode,
    message: err.message || 'Internal Server Error',
  };

  // Include error details in production for debugging (can be removed later)
  if (process.env.NODE_ENV === 'production') {
    // Include basic error info in production
    errorResponse.error = err.message || 'Internal Server Error';
    if (err.details) {
      errorResponse.details = err.details;
    }
  } else {
    errorResponse.stack = err.stack;
    errorResponse.details = err.details || null;
  }

  res.status(statusCode).json(errorResponse);
};

class CustomError extends Error {
  constructor(message, statusCode = 500, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    Error.captureStackTrace(this, this.constructor);
  }
}

// Async error wrapper for route handlers
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = { errorHandler, notFound, CustomError, asyncHandler };
