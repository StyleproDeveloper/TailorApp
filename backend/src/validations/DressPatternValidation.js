const Joi = require('joi');

const dressPatternValidationSchema = Joi.object({
  shop_id: Joi.number().required().messages({
    'any.required': 'Shop ID is required!',
  }),
  name: Joi.string().required().max(100).messages({
    'any.required': 'Name is required!',
    'any.max': 'Name cannot exceed 100 characters!',
  }),
  category: Joi.string().required().max(100).messages({
    'any.required': 'Category is required!',
    'any.max': 'Category cannot exceed 100 characters!',
  }),
  owner: Joi.string().optional().allow('', null),
});

module.exports = dressPatternValidationSchema;
