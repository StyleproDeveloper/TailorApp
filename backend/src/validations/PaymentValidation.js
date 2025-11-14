const Joi = require('joi');

// Date validation helper (YYYY-MM-DD format)
const dateOnly = () => {
  return Joi.string()
    .pattern(/^\d{4}-\d{2}-\d{2}$/)
    .messages({
      'string.pattern.base': 'Date must be in YYYY-MM-DD format',
    });
};

// Create Payment Schema
// Note: shop_id comes from URL params, not request body
const createPaymentSchema = Joi.object({
  orderId: Joi.number().required().messages({
    'any.required': 'Order ID is required!',
  }),
  paidAmount: Joi.number().required().min(0).messages({
    'any.required': 'Paid amount is required!',
    'number.min': 'Paid amount must be greater than or equal to 0',
  }),
  paymentDate: dateOnly().required().messages({
    'any.required': 'Payment date is required!',
  }),
  paymentType: Joi.string()
    .valid('advance', 'partial', 'final', 'other')
    .default('partial')
    .messages({
      'any.only': 'Payment type must be advance, partial, final, or other',
    }),
  notes: Joi.string().allow('').default(''),
  owner: Joi.string().optional(),
});

// Update Payment Schema
const updatePaymentSchema = Joi.object({
  paidAmount: Joi.number().min(0).messages({
    'number.min': 'Paid amount must be greater than or equal to 0',
  }),
  paymentDate: dateOnly(),
  paymentType: Joi.string()
    .valid('advance', 'partial', 'final', 'other')
    .messages({
      'any.only': 'Payment type must be advance, partial, final, or other',
    }),
  notes: Joi.string().allow(''),
});

module.exports = {
  createPaymentSchema,
  updatePaymentSchema,
};

