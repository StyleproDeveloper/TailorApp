const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const DressTypeDresspatternSchema = new Schema(
  {
    dressTypePatternId: {
      type: Number,
      required: true,
      unique: true,
    },
    dressTypeId: {
      type: Number,
      required: true,
      maxLength: 100,
      ref: 'Dresstype',
    },
    category: {
      type: String,
    },
    dressPatternId: {
      type: Number,
      required: true,
      ref: 'Dresspattern',
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
  'DressTypeDressPattern',
  DressTypeDresspatternSchema
);
