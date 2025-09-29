const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const MeasurementSchema = new Schema(
  {
    measurementId: {
      type: Number,
      required: true,
      unique: true,
    },
    name: {
      type: String,
      required: true,
      maxLength: 100,
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

module.exports = mongoose.model('Measurement', MeasurementSchema);
