const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const MeasurementHistorySchema = new Schema(
  {
    measurementHistorId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      unique: true,
    },
    customer: {
      type: String,
      required: true,
    },
    dressType: {
      type: String,
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

module.exports = mongoose.model('MeasurementHistory', MeasurementHistorySchema);
