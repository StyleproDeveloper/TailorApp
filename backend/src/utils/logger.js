/**
 * Simple Logger Utility
 * Provides structured logging with different log levels
 */
const logLevels = {
  ERROR: 0,
  WARN: 1,
  INFO: 2,
  DEBUG: 3,
};

const currentLogLevel = process.env.LOG_LEVEL 
  ? logLevels[process.env.LOG_LEVEL.toUpperCase()] || logLevels.INFO
  : process.env.NODE_ENV === 'production' ? logLevels.INFO : logLevels.DEBUG;

const formatMessage = (level, message, data = null) => {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...(data && { data }),
  };
  
  return JSON.stringify(logEntry);
};

const logger = {
  error: (message, error = null) => {
    if (currentLogLevel >= logLevels.ERROR) {
      const errorData = error ? {
        message: error.message,
        stack: process.env.NODE_ENV !== 'production' ? error.stack : undefined,
      } : null;
      console.error(formatMessage('ERROR', message, errorData));
    }
  },
  
  warn: (message, data = null) => {
    if (currentLogLevel >= logLevels.WARN) {
      console.warn(formatMessage('WARN', message, data));
    }
  },
  
  info: (message, data = null) => {
    if (currentLogLevel >= logLevels.INFO) {
      console.log(formatMessage('INFO', message, data));
    }
  },
  
  debug: (message, data = null) => {
    if (currentLogLevel >= logLevels.DEBUG) {
      console.log(formatMessage('DEBUG', message, data));
    }
  },
};

module.exports = logger;

