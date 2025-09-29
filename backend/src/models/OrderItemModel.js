const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const OrderItemSchema = Schema(
  {
    orderItemId: {
      type: Number,
      required: true,
      unique: true,
    },
    orderId: {
      type: Number,
      ref: 'Order',
    },
    orderItemMeasurementId: {
      type: Number,
      ref: 'OrderItemMeasurement',
    },
    orderItemPatternId: {
      type: Number,
      ref: 'OrderItemPattern',
    },
    dressTypeId: {
      type: Number,
      ref: 'DressType',
    },
    DressTypeMeasurementId: {
      type: Number,
      ref: 'DressTypeMeasurement',
    },
    DressTypePatternId: {
      type: Number,
      ref: 'DressTypeDressPattern',
    },
    amount: {
      type: Number,
    },
    special_instructions: {
      type: String,
    },
    recording: {
      type: String,
    },
    pictures: {
      type: [String],
    },
    delivery_date: {
      type: String,
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

module.exports = mongoose.model('OrderItem', OrderItemSchema);

OrderItemSchema.pre('save', function (next) {
  if (this.delivery_date) {
    this.delivery_date = moment(this.delivery_date).format('YYYY-MM-DD');
  }
  next();
});
