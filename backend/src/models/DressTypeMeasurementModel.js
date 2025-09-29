const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const DressTypeMeasurementSchema = new Schema(
  {
    dressTypeMeasurementId: {
      type: Number,
      unique: true,
    },
    name: {
      type: String,
      required: true,
      maxLength: 100,
    },
    dressTypeId: {
      type: Number,
      required: true,
    },
    measurementId: {
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

module.exports = mongoose.model(
  'DressTypeMeasurement',
  DressTypeMeasurementSchema
);
