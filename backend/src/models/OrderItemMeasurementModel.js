const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const OrderItemMeasurementSchema = new Schema(
  {
    orderItemMeasurementId: {
      type: Number,
      unique: true,
    },
    dressTypeId: {
      type: Number,
      ref: 'DressType',
    },
    customerId: {
      type: Number,
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
    length: {
      type: Number,
    },
    shoulder_width: {
      type: Number,
    },
    bust: {
      type: Number,
    },
    above_bust: {
      type: Number,
    },
    below_bust: {
      type: Number,
    },
    waist: {
      type: Number,
    },
    hip_circumference: {
      type: Number,
    },
    sleeve_length: {
      type: Number,
    },
    arm_hole: {
      type: Number,
    },
    ankle_circumference: {
      type: Number,
    },
    bicef_circumference: {
      type: Number,
    },
    elbow_circumference: {
      type: Number,
    },
    wrist_circumference: {
      type: Number,
    },
    front_neck_depth: {
      type: Number,
    },
    back_neck_depth: {
      type: Number,
    },
    thigh_circumference: {
      type: Number,
    },
    fly: {
      type: Number,
    },
    inseam: {
      type: Number,
    },
    crotch: {
      type: Number,
    },
    upper_front: {
      type: Number,
    },
    mid_front: {
      type: Number,
    },
    lower_front: {
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

module.exports = mongoose.model(
  'OrderItemMeasurement',
  OrderItemMeasurementSchema
);
