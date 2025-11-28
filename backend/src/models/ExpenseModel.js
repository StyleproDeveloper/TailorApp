const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const ExpenseSchema = new Schema(
  {
    expenseId: {
      type: Number,
      required: true,
      unique: true,
    },
    shop_id: {
      type: Number,
      required: true,
    },
    name: {
      type: String,
      required: true,
      maxlength: 100,
    },
    rent: {
      type: Number,
      default: 0,
      min: 0,
    },
    electricity: {
      type: Number,
      default: 0,
      min: 0,
    },
    salary: {
      type: Number,
      default: 0,
      min: 0,
    },
    miscellaneous: {
      type: Number,
      default: 0,
      min: 0,
    },
    owner: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

module.exports = mongoose.model('Expense', ExpenseSchema);
