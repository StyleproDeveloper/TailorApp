const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const OrderItemPatternSchema = new Schema(
  {
    orderItemPatternId: {
      type: Number,
      unique: true,
    },
    orderId: {
      type: Number,
      ref: 'Order',
      required: true,
    },
    orderItemId: {
      type: Number,
      ref: 'OrderItem',
      required: true,
    },
    patternId: {
      type: Number,
      ref: 'Pattern',
    },
    patterns: [
      {
        category: {
          type: String,
          required: true,
        },
        name: {
          type: [String],
          required: true,
        },
      },
    ],
    owner: {
      type: String,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);
module.exports = mongoose.model('OrderItemPattern', OrderItemPatternSchema);
