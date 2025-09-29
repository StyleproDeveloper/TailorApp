const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const RoleSchema = new Schema(
  {
    roleId: {
      type: Number,
      required: true,
      unique: true,
    },
    name: {
      type: String,
      required: true,
      maxLength: 100,
    },
    viewOrder: {
      type: Boolean,
      default: false,
    },
    editOrder: {
      type: Boolean,
      default: false,
    },
    createOrder: {
      type: Boolean,
      default: false,
    },
    viewPrice: {
      type: Boolean,
      default: false,
    },
    viewShop: {
      type: Boolean,
      default: false,
    },
    editShop: {
      type: Boolean,
      default: false,
    },
    viewCustomer: {
      type: Boolean,
      default: false,
    },
    editCustomer: {
      type: Boolean,
      default: false,
    },
    administration: {
      type: Boolean,
      default: false,
    },
    viewReports: {
      type: Boolean,
      default: false,
    },
    addDressItem: {
      type: Boolean,
      default: false,
    },
    payments: {
      type: Boolean,
      default: false,
    },
    viewAllBranches: {
      type: Boolean,
      default: false,
    },
    assignDressItem: {
      type: Boolean,
      default: false,
    },
    manageOrderStatus: {
      type: Boolean,
      default: false,
    },
    manageWorkShop: {
      type: Boolean,
      default: false,
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

module.exports = mongoose.model('Role', RoleSchema);
