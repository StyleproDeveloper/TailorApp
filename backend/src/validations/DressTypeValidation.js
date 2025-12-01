const Joi = require('joi');

const dressTypeSchema = Joi.object({
  shop_id: Joi.number().required().messages({
    'any.required': 'Shop ID is required!',
  }),
  name: Joi.string().max(100).required().messages({
    'any.required': 'Name is required!',
  }),
  imageUrl: Joi.string().uri().allow('', null).optional().messages({
    'string.uri': 'Image URL must be a valid URL',
  }),
  owner: Joi.string().optional(),
});

module.exports = dressTypeSchema;
