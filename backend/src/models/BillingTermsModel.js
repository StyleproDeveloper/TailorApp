const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const BillingTermSchema = new Schema(
  {
    billingTermId: {
      type: Number,
      required: true,
      unique: true,
    },
    terms: {
      type: String,
    },
    gst_no: {
      type: String,
    },
    gst_reg_date: {
      type: Date,
    },
    gst_state: {
      type: String,
    },
    gst_address: {
      type: String,
    },
    gst_available: {
      type: Boolean,
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

module.exports = mongoose.model('BillingTerm', BillingTermSchema);
