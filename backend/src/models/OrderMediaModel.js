const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const OrderMediaSchema = Schema(
  {
    orderMediaId: {
      type: Number,
      required: true,
      unique: true,
    },
    orderId: {
      type: Number,
      required: true,
      ref: 'Order',
    },
    orderItemId: {
      type: Number,
      required: true,
      ref: 'OrderItem',
    },
    shopId: {
      type: Number,
      required: true,
    },
    mediaType: {
      type: String,
      required: true,
      enum: ['image', 'audio'],
    },
    mediaUrl: {
      type: String,
      required: true,
    },
    fileName: {
      type: String,
      required: true,
    },
    fileSize: {
      type: Number, // Size in bytes
      default: 0,
    },
    mimeType: {
      type: String,
      default: null,
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
OrderMediaSchema.index({ orderId: 1 });
OrderMediaSchema.index({ orderItemId: 1 });
OrderMediaSchema.index({ orderId: 1, orderItemId: 1 });
OrderMediaSchema.index({ shopId: 1 });

module.exports = mongoose.model('OrderMedia', OrderMediaSchema);

