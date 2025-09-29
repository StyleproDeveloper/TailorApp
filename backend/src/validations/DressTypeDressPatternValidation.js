const Joi = require('joi');

const DressTypeDressPatternValidationSchema = Joi.array()
  .items(
    Joi.object({
      shop_id: Joi.number().required().messages({
        'any.required': 'Shop ID is required!',
      }),
      dressTypeId: Joi.number().required().messages({
        'any.required': 'Dress Type is required!',
      }),
      category: Joi.string().optional().allow('', null),
      dressPatternId: Joi.number().required().messages({
        'any.required': 'Dress Pattern is required!',
      }),
      dressTypePatternId: Joi.number().optional().allow('', null),
      owner: Joi.string().optional().allow('', null),
    })
  )
  .min(1)
  .messages({
    'array.min': 'At least one Dress Type Dress Pattern record is required!',
    'array.base': 'Input must be an array of objects!',
  });

module.exports = DressTypeDressPatternValidationSchema;
