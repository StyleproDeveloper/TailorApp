const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const ChangeHistorySchema = new Schema(
  {
    changeHistoryId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      unique: true,
    },
    dateAndTime: {
      type: Date,
    },
    table: {
      type: String,
    },
    filed: {
      type: String,
    },
    oldValue: {
      type: String,
    },
    newValue: {
      type: String,
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

module.exports = mongoose.model('ChangeHistory', ChangeHistorySchema);
