const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const UserBranchSchema = new Schema(
  {
    userBranchId: {
      type: Number,
      required: true,
      unique: true,
    },
    userId: {
      type: Number,
      ref: 'User',
    },
    branchId: {
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

module.exports = mongoose.model('UserBranch', UserBranchSchema);
