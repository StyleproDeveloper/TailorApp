const { max } = require('lodash');
const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const UserSchema = new Schema(
  {
    userId: {
      type: Number,
      required: true,
      unique: true,
    },
    shopId: {
      type: Number,
      ref: 'Shop',
      required: true,
    },
    mobile: {
      type: String,
      required: true,
      unique: true,
    },
    branchId: {
      type: Number,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    name: {
      type: String,
      required: true,
    },
    roleId: {
      type: Number,
      required: true,
    },
    secondaryMobile: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    email: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    addressLine1: {
      type: String,
      maxlength: 150,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    street: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    city: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    postalCode: {
      type: Number,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

module.exports = mongoose.model('User', UserSchema);
