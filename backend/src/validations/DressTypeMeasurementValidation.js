const Joi = require('joi');

const dressTypeMeasurementValidationSchema = Joi.array()
  .items(
    Joi.object({
      shop_id: Joi.number().integer().positive().required().messages({
        'any.required': 'Shop ID is required!',
        'number.base': 'Shop ID must be a number!',
        'number.integer': 'Shop ID must be an integer!',
        'number.positive': 'Shop ID must be a positive number!',
      }),
      name: Joi.string().required().max(100).messages({
        'any.required': 'Name is required!',
        'any.max': 'Name cannot exceed 100 characters!',
      }),
      dressTypeId: Joi.number().integer().positive().required().messages({
        'any.required': 'Dress Type is required!',
        'number.base': 'Dress Type ID must be a number!',
        'number.integer': 'Dress Type ID must be an integer!',
        'number.positive': 'Dress Type ID must be a positive number!',
      }),
      measurementId: Joi.number().integer().positive().required().messages({
        'any.required': 'Measurement is required!',
        'number.base': 'Measurement ID must be a number!',
        'number.integer': 'Measurement ID must be an integer!',
        'number.positive': 'Measurement ID must be a positive number!',
      }),
      dressTypeMeasurementId: Joi.number().optional().allow('', null),
      owner: Joi.string().allow('', null),
    })
  )
  .min(1)
  .messages({
    'array.min': 'At least one Dress Type Measurement record is required!',
    'array.base': 'Input must be an array of objects!',
  });

module.exports = dressTypeMeasurementValidationSchema;
