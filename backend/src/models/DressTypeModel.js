const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const DressTypeSchema = new Schema(
  {
    dressTypeId: {
      type: Number,
      required: true,
      unique: true,
    },
    name: {
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

// Middleware to auto-update the `modifiedDate` field on save
DressTypeSchema.pre('save', function (next) {
  this.modifiedDate = Date.now();
  next();
});

module.exports = mongoose.model('DressType', DressTypeSchema);
