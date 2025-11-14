const mongoose = require('mongoose');
const moment = require('moment');

const Schema = mongoose.Schema;

const PaymentSchema = new Schema(
  {
    paymentId: {
      type: Number,
      required: true,
      unique: true,
    },
    shop_id: {
      type: Number,
      required: true,
    },
    orderId: {
      type: Number,
      required: true,
    },
    paidAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    paymentDate: {
      type: String,
      required: true,
    },
    paymentType: {
      type: String,
      enum: ['advance', 'partial', 'final', 'other'],
      default: 'partial',
    },
    notes: {
      type: String,
      default: '',
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
PaymentSchema.index({ paymentId: 1 });
PaymentSchema.index({ orderId: 1 });
PaymentSchema.index({ shop_id: 1 });
PaymentSchema.index({ paymentDate: -1 });

// Format payment date before saving
PaymentSchema.pre('save', function (next) {
  if (this.paymentDate) {
    this.paymentDate = moment(this.paymentDate).format('YYYY-MM-DD');
  }
  next();
});

module.exports = mongoose.model('payment', PaymentSchema);

