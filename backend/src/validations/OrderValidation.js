// validation/orderSchema.js
const Joi = require('joi');
const moment = require('moment');

// Custom Date Validator
const dateOnly = () =>
  Joi.string()
    .custom((value, helpers) => {
      if (!moment(value, 'YYYY-MM-DD', true).isValid()) {
        return helpers.error('date.format');
      }
      return value;
    })
    .messages({
      'date.format': 'Date must be in YYYY-MM-DD format',
    });

// Measurement Schema
const measurementSchema = Joi.object({
  orderItemMeasurementId: Joi.number().messages({
    'any.required': 'Measurement ID is required',
  }),
  length: Joi.number().allow(null),
  shoulder_width: Joi.number().allow(null),
  bust: Joi.number().allow(null),
  above_bust: Joi.number().allow(null),
  below_bust: Joi.number().allow(null),
  waist: Joi.number().allow(null),
  hip_circumference: Joi.number().allow(null),
  sleeve_length: Joi.number().allow(null),
  arm_hole: Joi.number().allow(null),
  bicef_circumference: Joi.number().allow(null),
  ankle_circumference: Joi.number().allow(null),
  elbow_circumference: Joi.number().allow(null),
  wrist_circumference: Joi.number().allow(null),
  front_neck_depth: Joi.number().allow(null),
  back_neck_depth: Joi.number().allow(null),
  thigh_circumference: Joi.number().allow(null),
  fly: Joi.number().allow(null),
  inseam: Joi.number().allow(null),
  crotch: Joi.number().allow(null),
  upper_front: Joi.number().allow(null),
  mid_front: Joi.number().allow(null),
  lower_front: Joi.number().allow(null),
}).unknown(true); // Allow additional fields to prevent validation errors

// Pattern Schema
const patternSchema = Joi.array()
  .items(
    Joi.object({
      orderItemPatternId: Joi.number().allow(null).optional().messages({
        'any.required': 'Pattern ID is required',
      }),
      category: Joi.string().allow('', null).optional().messages({
        'any.required': 'Pattern category is required',
      }),
      name: Joi.array().items(Joi.string()).allow(null).empty([]).optional().messages({
        'any.required': 'Pattern names are required',
      }),
    }).unknown(true) // Allow additional fields
  )
  .min(0) // Allow empty array for new items
  .messages({
    'any.required': 'Pattern is required',
  });

// Item Schema
const itemSchema = Joi.object({
  orderItemId: Joi.number().allow(null).optional().messages({
    'any.required': 'Item ID is required',
  }),
  dressTypeId: Joi.number().allow(null).optional().messages({
    'any.required': 'Dress Type is required!',
  }),
  Measurement: measurementSchema.allow(null, {}).optional().messages({
    'any.required': 'Measurement is required',
  }),
  Pattern: patternSchema.allow(null).optional().messages({
    'any.required': 'Pattern is required',
  }),
  special_instructions: Joi.string().allow(''),
  recording: Joi.string().allow(''),
  videoLink: Joi.string().allow(''),
  //   Pictures: Joi.array().items(Joi.string().uri()).default([]),
  pictures: Joi.array().items(Joi.string()).default([]),
  delivery_date: dateOnly().required(),
  amount: Joi.number().required(),
  status: Joi.string()
    .valid('received', 'in-progress', 'completed', 'delivered')
    .required(),
  owner: Joi.string().required(),
});

// Additional Cost Schema
const additionalCostSchema = Joi.object({
  additionalCostName: Joi.string().required(),
  additionalCost: Joi.number().required(),
});

// Order Schema
const orderSchema = Joi.object({
  shop_id: Joi.number().required().messages({
    'any.required': 'Shop ID is required!',
  }),
  branchId: Joi.number().required(),
  customerId: Joi.number().required(),
  stitchingType: Joi.number().valid(0, 1, 2).required().messages({
    'any.only':
      'Stitching type must be Stitching (0), Alteration (1), or Material (2).',
  }),
  noOfMeasurementDresses: Joi.number().default(0),
  quantity: Joi.number().required(),
  urgent: Joi.boolean().default(false),
  status: Joi.string()
    .valid('received', 'in-progress', 'completed', 'delivered')
    .default('received'),
  estimationCost: Joi.number().required(),
  advancereceived: Joi.number().default(0),
  advanceReceivedDate: dateOnly().allow('').optional(),
  gst: Joi.boolean().default(false),
  gst_amount: Joi.number().default(0),
  Courier: Joi.boolean().default(false),
  courierCharge: Joi.number().default(0),
  discount: Joi.number().default(0),
  owner: Joi.string().required(),
});

// Main Payload Schema
const createOrderPayloadSchema = Joi.object({
  Order: orderSchema.required(),
  Item: Joi.array().items(itemSchema).min(1).required(),
  AdditionalCosts: Joi.array().items(additionalCostSchema).allow(null).optional().default([]),
});

module.exports = createOrderPayloadSchema;
