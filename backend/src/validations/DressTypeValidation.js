const Joi = require('joi');

const dressTypeSchema = Joi.object({
  shop_id: Joi.number().required().messages({
    'any.required': 'Shop ID is required!',
  }),
  name: Joi.string().max(100).required().messages({
    'any.required': 'Name is required!',
  }),
  owner: Joi.string().optional(),
});

module.exports = dressTypeSchema;
