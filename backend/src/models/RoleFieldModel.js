const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const RoleFieldSchema = new Schema(
  {
    roleFieldId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      unique: true,
    },
    roleId: {
      type: Number,
      ref: 'Role',
    },
    table: {
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

module.exports = mongoose.model('RoleField', RoleFieldSchema);
