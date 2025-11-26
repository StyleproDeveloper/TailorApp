const { CustomError } = require('../utils/error.handlers');

const validateRequest = (schema) => (req, res, next) => {
    const { error } = schema.validate(req.body, { 
      abortEarly: false,
      allowUnknown: true,
      stripUnknown: false
    });
  
    if (error) {
      const errorMessages = error.details.map((detail) => detail.message).join(', ');
      const validationError = new CustomError(`Validation failed: ${errorMessages}`, 400, error.details);
      return next(validationError);
    }
    
    next();
  };
  
  module.exports = validateRequest;
  