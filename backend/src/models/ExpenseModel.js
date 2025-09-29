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
