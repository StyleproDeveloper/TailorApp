const Joi = require('joi');

const customerValidationSchema = Joi.object({
  shop_id: Joi.number().required().messages({
    'any.required': 'Shop ID is required!',
  }),

  name: Joi.string()
    .trim()
    .max(100)
    .regex(/^[a-zA-Z\s]+$/)
    .required()
    .messages({
      'string.pattern.base': 'Name cannot contain numbers!',
      'string.empty': 'Name is required!',
      'any.required': 'Name is required!',
    }),

  gender: Joi.string().valid('male', 'female', 'other').required().messages({
    'any.only': 'Gender must be one of [male, female, other]!',
    'any.required': 'Gender is required!',
  }),

  mobile: Joi.string()
    .trim()
    .required()
    .pattern(/^\+?[0-9]+$/)
    .messages({
      'string.pattern.base': 'Invalid mobile number format!',
      'string.empty': 'Mobile number is required!',
      'any.required': 'Mobile number is required!',
    }),

  secondaryMobile: Joi.string()
    .trim()
    .allow('', null)
    .pattern(/^\+?[0-9]+$/)
    .messages({
      'string.pattern.base': 'Invalid secondary mobile number format!',
    }),

  email: Joi.string()
    .trim()
    .allow('', null)
    .email({ tlds: { allow: false } })
    .messages({
      'string.email': 'Invalid email format!',
    }),

  dateOfBirth: Joi.date().less('now').allow('', null).messages({
    'date.less': 'Date of birth cannot be in the future!',
  }),

  addressLine1: Joi.string().trim().max(150).allow('', null),

  remark: Joi.string().trim().allow('', null),

  gst: Joi.string().trim().allow('', null),

  notificationOptIn: Joi.boolean().required().default(true).messages({
    'any.required': 'Notification Opt-In is required!',
  }),

  owner: Joi.string().trim().allow('', null),

  branch_id: Joi.string().trim().required().messages({
    'string.empty': 'Branch ID is required!',
    'any.required': 'Branch ID is required!',
  }),
});

module.exports = customerValidationSchema;
