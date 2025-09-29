const Joi = require('joi');

const ShopValidationSchema = Joi.object({
  branch_id: Joi.number().allow('', null).optional(),

  yourName: Joi.string().max(100).required().messages({
    'any.required': 'Your name is required!',
    'string.max': 'Your name cannot exceed 100 characters!',
  }),

  shopName: Joi.string()
    .max(100)
    .regex(/^[a-zA-Z\s]+$/)
    .required()
    .messages({
      'any.required': 'Shop name is required!',
      'string.max': 'Shop name cannot exceed 100 characters!',
      'string.pattern.base': 'Shop name cannot contain numbers!',
    }),

  code: Joi.string().max(80).optional().allow('', null),

  shopType: Joi.string()
    .allow('', null)
    .valid('Store', 'Workshop')
    .optional()
    .messages({
      'any.only': 'Shop Type must be either Store or Workshop!',
    }),

  mobile: Joi.string()
    .pattern(/^\+?[0-9]+$/)
    .required()
    .messages({
      'any.required': 'Mobile number is required!',
      'string.pattern.base': 'Mobile number must be a valid phone number!',
    }),

  secondaryMobile: Joi.string()
    .allow('', null)
    .pattern(/^\+?[0-9]+$/)
    .optional()
    .messages({
      'string.pattern.base':
        'Secondary Mobile number must be a valid phone number!',
    }),

  email: Joi.string().allow('', null).email().optional().messages({
    'string.email': 'Invalid email format!',
  }),

  // Allow common website formats and bare domains (with or without protocol)
  website: Joi.string()
    .allow('', null)
    .pattern(/^(https?:\/\/)?([\w-]+\.)+[A-Za-z]{2,}(\/.*)?$/)
    .optional()
    .messages({
      'string.pattern.base': 'Invalid website URL!',
    }),

  instagram_url: Joi.string()
    .allow('', null)
    .pattern(/^(https?:\/\/)?([\w-]+\.)+[A-Za-z]{2,}(\/.*)?$/)
    .optional()
    .messages({
      'string.pattern.base': 'Invalid Instagram URL!',
    }),

  facebook_url: Joi.string()
    .allow('', null)
    .pattern(/^(https?:\/\/)?([\w-]+\.)+[A-Za-z]{2,}(\/.*)?$/)
    .optional()
    .messages({
      'string.pattern.base': 'Invalid Facebook URL!',
    }),

  addressLine1: Joi.string().allow('', null).max(150).optional().messages({
    'string.max': 'Address Line 1 cannot exceed 150 characters!',
  }),

  street: Joi.string().allow('', null).max(150).optional().messages({
    'string.max': 'Street cannot exceed 150 characters!',
  }),

  city: Joi.string().allow('', null).max(100).optional().messages({
    'string.max': 'City cannot exceed 100 characters!',
  }),

  state: Joi.string().allow('', null).optional(),

  postalCode: Joi.alternatives()
    .try(
      Joi.string().length(6).pattern(/^[0-9]+$/),
      Joi.number().integer().min(100000).max(999999)
    )
    .allow('', null)
    .optional()
    .messages({
      'alternatives.match': 'Postal Code must be a 6-digit number!',
      'string.length': 'Postal Code must be exactly 6 digits!',
      'string.pattern.base': 'Postal Code must contain only numbers!',
      'number.base': 'Postal Code must be a 6-digit number!',
      'number.min': 'Postal Code must be exactly 6 digits!',
      'number.max': 'Postal Code must be exactly 6 digits!',
    }),

  subscriptionType: Joi.alternatives()
    .try(
      Joi.number().valid(0, 1, 2),
      Joi.string().valid('Trial', 'Paid-monthly', 'Paid-yearly')
    )
    .allow('', null)
    .optional()
    .messages({
      'alternatives.match': 'Subscription Type must be 0/1/2 or Trial/Paid-monthly/Paid-yearly!',
      'any.only': 'Subscription Type must be 0 (Trial), 1 (Paid - Monthly), or 2 (Paid - Yearly)!',
    }),

  subscriptionEndDate: Joi.alternatives()
    .try(Joi.date(), Joi.string().isoDate())
    .allow('', null)
    .optional()
    .messages({
      'alternatives.match': 'Subscription End Date must be a valid date!',
      'date.base': 'Subscription End Date must be a valid date!',
      'string.isoDate': 'Subscription End Date must be an ISO date (YYYY-MM-DD)!',
    }),

  setupComplete: Joi.boolean().optional().messages({
    'boolean.base': 'Setup Complete must be a boolean value!',
  }),
});

module.exports = ShopValidationSchema;
