const mongoose = require('mongoose');

const Schema = mongoose.Schema;

// const CustomerSchema = new Schema(
//   {
//     customerId: {
//       type: Number,
//       required: true,
//       unique: true,
//     },
//     name: {
//       type: String,
//       required: true,
//       maxlength: 100,
//       validate: {
//         validator: function (v) {
//           return /^[a-zA-Z\s]+$/.test(v); // Only letters and spaces allowed
//         },
//         message: (props) =>
//           `${props.value} is not a valid name! Names cannot contain numbers.`,
//       },
//     },
//     gender: {
//       type: String,
//       required: true,
//       enum: ['male', 'feMale', 'other'], // Dropdown values
//     },
//     mobile: {
//       type: String,
//       required: true,
//       unique: true,
//       validate: {
//         validator: function (v) {
//           return /^\+?[0-9]+$/.test(v); // Allow only numbers and '+' sign
//         },
//         message: (props) => `${props.value} is not a valid phone number!`,
//       },
//     },
//     secondaryMobile: {
//       type: String,
//       validate: {
//         validator: function (v) {
//           // Validate only if secondaryMobile has a value
//           return !v || /^\+?[0-9]+$/.test(v); // Allow only numbers and '+' or null
//         },
//         message: (props) => `${props.value} is not a valid phone number!`,
//       },
//     },
//     email: {
//       type: String,
//       validate: {
//         validator: function (v) {
//           // Validate only if email has a value
//           return !v || /^\S+@\S+\.\S+$/.test(v); // Allow valid email format or null
//         },
//         message: (props) => `${props.value} is not a valid email!`,
//       },
//     },
//     dateOfBirth: {
//       type: Date,
//       validate: {
//         validator: function (v) {
//           // Validate only if dateOfBirth has a value
//           return !v || v <= new Date(); // No future dates
//         },
//         message: (props) => `Date of birth cannot be in the future.`,
//       },
//     },
//     addressLine1: {
//       type: String,
//       maxlength: 150,
//     },
//     remark: {
//       type: String,
//     },
//     notificationOptIn: {
//       type: Boolean,
//       required: true,
//       default: true, // Default to TRUE
//     },
//     owner: {
//       type: String,
//     },
//     branch_id: {
//       type: String,
//       required: true,
//     },
//   },
//   {
//     timestamps: true,
//     versionKey: false,
//   }
// );

const CustomerSchema = new Schema(
  {
    customerId: {
      type: Number,
      required: true,
      unique: true,
    },
    name: {
      type: String,
      required: true,
      maxlength: 100,
      validate: {
        validator: function (v) {
          return /^[a-zA-Z\s]+$/.test(v);
        },
        message: (props) =>
          `${props.value} is not a valid name! Names cannot contain numbers.`,
      },
    },
    gender: {
      type: String,
      required: true,
      enum: ['male', 'female', 'other'],
    },
    mobile: {
      type: String,
      required: true,
      unique: true,
      validate: {
        validator: function (v) {
          return /^\+?[0-9]+$/.test(v);
        },
        message: (props) => `${props.value} is not a valid phone number!`,
      },
    },
    secondaryMobile: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
      validate: {
        validator: function (v) {
          return !v || /^\+?[0-9]+$/.test(v);
        },
        message: (props) => `${props.value} is not a valid phone number!`,
      },
    },
    email: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
      validate: {
        validator: function (v) {
          return !v || /^\S+@\S+\.\S+$/.test(v);
        },
        message: (props) => `${props.value} is not a valid email!`,
      },
    },
    dateOfBirth: {
      type: Date,
      default: null,
      set: (v) => (v === '' ? null : v),
      validate: {
        validator: function (v) {
          return !v || v <= new Date();
        },
        message: `Date of birth cannot be in the future.`,
      },
    },
    addressLine1: {
      type: String,
      maxlength: 150,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    remark: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    gst: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    notificationOptIn: {
      type: Boolean,
      required: true,
      default: true,
    },
    owner: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    branch_id: {
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

module.exports = mongoose.model('Customer', CustomerSchema);
