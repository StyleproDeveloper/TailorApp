const Joi = require('joi');

// Expense Entry Schema
const expenseEntrySchema = Joi.object({
  expenseType: Joi.string()
    .valid('rent', 'electricity', 'salary', 'miscellaneous')
    .required()
    .messages({
      'any.required': 'Expense type is required!',
      'any.only': 'Expense type must be rent, electricity, salary, or miscellaneous',
    }),
  amount: Joi.number().required().min(0).messages({
    'any.required': 'Amount is required!',
    'number.min': 'Amount must be greater than or equal to 0',
  }),
  date: Joi.date().required().messages({
    'any.required': 'Date is required!',
    'date.base': 'Date must be a valid date',
  }),
});

// Create Expense Schema
const createExpenseSchema = Joi.object({
  shop_id: Joi.number().required().messages({
    'any.required': 'Shop ID is required!',
  }),
  name: Joi.string().allow(null, '').max(100).optional().messages({
    'string.max': 'Expense name cannot exceed 100 characters!',
  }),
  entries: Joi.array().items(expenseEntrySchema).min(1).required().messages({
    'any.required': 'At least one expense entry is required!',
    'array.min': 'At least one expense entry is required!',
  }),
  // Keep old fields for backward compatibility (optional)
  rent: Joi.number().min(0).optional(),
  electricity: Joi.number().min(0).optional(),
  salary: Joi.number().min(0).optional(),
  miscellaneous: Joi.number().min(0).optional(),
  owner: Joi.string().optional(),
});

// Update Expense Schema
const updateExpenseSchema = Joi.object({
  name: Joi.string().max(100).messages({
    'string.max': 'Expense name cannot exceed 100 characters!',
  }),
  entries: Joi.array().items(expenseEntrySchema).min(1).messages({
    'array.min': 'At least one expense entry is required!',
  }),
  // Keep old fields for backward compatibility (optional)
  rent: Joi.number().min(0).optional(),
  electricity: Joi.number().min(0).optional(),
  salary: Joi.number().min(0).optional(),
  miscellaneous: Joi.number().min(0).optional(),
  owner: Joi.string().optional(),
});

module.exports = {
  createExpenseSchema,
  updateExpenseSchema,
};

