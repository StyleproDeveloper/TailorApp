const validateRequest = (schema) => (req, res, next) => {
    const { error } = schema.validate(req.body, { 
      abortEarly: false,
      allowUnknown: true,
      stripUnknown: false
    });
  
    if (error) {
      return res.status(400).json({
        error: error.details.map((detail) => detail.message),
      });
    }
    
    next();
  };
  
  module.exports = validateRequest;
  