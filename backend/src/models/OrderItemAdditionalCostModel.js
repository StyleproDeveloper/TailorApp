const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const OrderItemAdditionalCostSchema = Schema(
  {
    orderItemAdditionalCostId: {
      type: Number,
      required: true,
      unique: true,
    },
    orderItemId: {
      type: Number,
      required: true,
      ref: 'OrderItem',
    },
    orderId: {
      type: Number,
      required: true,
      ref: 'Order',
    },
    additionalCostName: {
      type: String,
      required: true,
    },
    additionalCost: {
      type: Number,
      required: true,
    },
    owner: {
      type: String,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Add indexes for better query performance
OrderItemAdditionalCostSchema.index({ orderId: 1 });
OrderItemAdditionalCostSchema.index({ orderItemId: 1 });

module.exports = mongoose.model('OrderItemAdditionalCost', OrderItemAdditionalCostSchema);

