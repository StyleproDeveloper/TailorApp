const { times } = require('lodash');
const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const DressPatternSchema = Schema(
  {
    dressPatternId: {
      type: Number,
      required: true,
      unique: true,
    },
    name: {
      type: String,
      maxlength: 100,
    },
    DressPattern: {
      type: String,
      maxlength: 100,
    },
    category: {
      type: String,
      required: true,
      maxLength: 100,
    },
    selection: {
      type: String,
    },
    owner: {
      type: String,
    },
  },
  {
    timestamps: true,
    versionKey: false,
    strict: false, // Allow fields not defined in schema (like DressPattern from old data)
  }
);

module.exports = mongoose.model('Dresspattern', DressPatternSchema);
