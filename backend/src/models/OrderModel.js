const mongoose = require('mongoose');
const { StitchingTypes } = require('../utils/CommonEnumValues');
const moment = require('moment');

const Schema = mongoose.Schema;

const OrderSchema = new Schema(
  {
    orderId: {
      type: Number,
      required: true,
      unique: true,
    },
    branchId: {
      type: Number,
    },
    customerId: {
      type: Number,
    },
    stitchingType: {
      type: Number,
      enum: StitchingTypes?.map((item) => item?.value),
      default: StitchingTypes[0]?.value,
    },
    // specialInstructions: {
    //   type: String,
    //   maxLength: 500,
    // },
    // recording: {
    //   type: String,
    // },
    // videoLink: {
    //   type: String,
    // },
    // measurementDress: {
    //   type: Boolean,
    //   enum: [true, false],
    // },
    noOfMeasurementDresses: {
      type: Number,
    },
    quantity: {
      type: Number,
    },
    // stitchingCharge: {
    //   type: Number,
    // },
    // deliveryDate: {
    //   type: String,
    // },
    // trialDate: {
    //   type: String,
    // },
    // functionDate: {
    //   type: String,
    // },
    urgent: {
      type: Boolean,
      enum: [true, false],
    },
    status: {
      type: String,
    },
    estimationCost: {
      type: Number,
    },
    advancereceived: {
      type: Number,
    },
    advanceReceivedDate: {
      type: String,
    },
    gst: {
      type: Boolean,
      default: false,
    },
    gst_amount: {
      type: Number,
    },
    courier: {
      type: Boolean,
      default: false,
    },
    courierCharge: {
      type: Number,
    },
    discount: {
      type: Number,
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

module.exports = mongoose.model('order', OrderSchema);

OrderSchema.pre('save', function (next) {
  if (this.advanceReceivedDate) {
    this.advanceReceivedDate = moment(this.advanceReceivedDate).format(
      'YYYY-MM-DD'
    );
  }
  if (this.deliveryDate) {
    this.deliveryDate = moment(this.deliveryDate).format('YYYY-MM-DD');
  }
  if (this.trialDate) {
    this.trialDate = moment(this.trialDate).format('YYYY-MM-DD');
  }
  if (this.functionDate) {
    this.functionDate = moment(this.functionDate).format('YYYY-MM-DD');
  }
  next();
});
