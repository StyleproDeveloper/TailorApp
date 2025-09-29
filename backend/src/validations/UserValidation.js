const Joi = require('joi');

const userSchema = Joi.object({
  shopId: Joi.number().required().messages({
    'any.required': 'Shop ID is required!',
  }),
  branchId: Joi.number().optional(),

  mobile: Joi.alternatives()
    .try(
      Joi.string()
        .pattern(/^\+?[0-9]+$/)
        .messages({
          'string.pattern.base': 'Mobile number must be a valid phone number!',
        }),
      Joi.allow(null, '')
    )
    .required()
    .messages({
      'any.required': 'Mobile number is required!',
    }),

  name: Joi.string().max(80).required().messages({
    'any.required': 'Name is required!',
  }),

  roleId: Joi.number().required().messages({
    'any.required': 'Role ID is required!',
  }),

  secondaryMobile: Joi.alternatives().try(
    Joi.string()
      .pattern(/^\+?[0-9]+$/)
      .messages({
        'string.pattern.base':
          'Secondary mobile number must be a valid phone number!',
      }),
    Joi.allow(null, '')
  ),

  email: Joi.alternatives().try(
    Joi.string().email().messages({
      'string.email': 'Invalid email format!',
    }),
    Joi.allow(null, '')
  ),

  addressLine1: Joi.string().max(150).allow(null, ''),
  street: Joi.string().max(150).allow(null, ''),
  city: Joi.string().max(100).allow(null, ''),

  postalCode: Joi.alternatives().try(
    Joi.number().integer().min(100000).max(999999).messages({
      'number.min': 'Postal code must be at least 6 digits!',
      'number.max': 'Postal code must not exceed 6 digits!',
    }),
    Joi.allow(null, '')
  ),
});

module.exports = userSchema;
