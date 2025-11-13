const mongoose = require('mongoose');
const {
  SubscriptionEnum,
  SubscriptionEnumMapping,
} = require('../utils/CommonEnumValues');

// const ShopInfoSchema = new mongoose.Schema(
//   {
//     shop_id: {
//       type: Number,
//       required: true,
//       unique: true,
//     },
//     branch_id: {
//       type: Number,
//     },
//     yourName: {
//       type: String,
//     },
//     shopName: {
//       type: String,
//     },
//     code: {
//       type: String,
//     },
//     shopType: {
//       type: String,
//     },
//     mobile: {
//       type: String,
//     },
//     secondaryMobile: {
//       type: String,
//     },
//     email: {
//       type: String,
//     },
//     website: {
//       type: String,
//     },
//     instagram_url: {
//       type: String,
//     },
//     facebook_url: {
//       type: String,
//     },
//     addressLine1: {
//       type: String,
//     },
//     street: {
//       type: String,
//     },
//     city: {
//       type: String,
//     },
//     state: {
//       type: String,
//     },
//     postalCode: {
//       type: Number,
//     },
//     subscriptionType: {
//       type: String,
//       enum: Object.values(SubscriptionEnum),
//       default: SubscriptionEnum.TRIAL,
//     },
//     subscriptionEndDate: {
//       type: Date,
//     },
//   },
//   {
//     timestamps: true,
//     versionKey: false,
//   }
// );

const ShopInfoSchema = new mongoose.Schema(
  {
    shop_id: {
      type: Number,
      required: true,
      unique: true,
    },
    branch_id: {
      type: Number,
      default: null,
    },
    yourName: {
      type: String,
      required: true,
      maxlength: 100,
    },
    shopName: {
      type: String,
      required: true,
      maxlength: 100,
      trim: true,
    },
    code: {
      type: String,
      maxlength: 80,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    shopType: {
      type: String,
      enum: ['Store', 'Workshop'],
      default: null,
    },
    mobile: {
      type: String,
      required: true,
      unique: true,
      validate: {
        validator: function (v) {
          return /^\+?[0-9]+$/.test(v);
        },
        message: 'Invalid mobile number format!',
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
        message: 'Invalid secondary mobile number format!',
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
        message: 'Invalid email format!',
      },
    },
    website: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
      validate: {
        validator: function (v) {
          return !v || /^(https?:\/\/)?([\w\d-]+\.)+[\w]{2,}(\/.*)?$/.test(v);
        },
        message: 'Invalid website URL!',
      },
    },
    instagram_url: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
      validate: {
        validator: function (v) {
          return (
            !v ||
            /^(https?:\/\/)?([\w-]+\.)+[\w-]{2,}(\/.*)?$/.test(v)
          );
        },
        message: 'Invalid Instagram URL!',
      },
    },
    facebook_url: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
      validate: {
        validator: function (v) {
          return (
            !v ||
            /^(https?:\/\/)?([\w-]+\.)+[\w-]{2,}(\/.*)?$/.test(v)
          );
        },
        message: 'Invalid Facebook URL!',
      },
    },
    addressLine1: {
      type: String,
      maxlength: 150,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    street: {
      type: String,
      maxlength: 150,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    city: {
      type: String,
      maxlength: 100,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    state: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    postalCode: {
      type: String,
      default: null,
      set: (v) => (v === '' ? null : v),
      validate: {
        validator: function (v) {
          return !v || /^[0-9]{6}$/.test(v);
        },
        message: 'Postal Code must be exactly 6 digits!',
      },
    },
    subscriptionType: {
      type: String,
      enum: Object.values(SubscriptionEnum),
      default: SubscriptionEnum.TRIAL,
    },
    subscriptionEndDate: {
      type: Date,
      default: null,
      set: (v) => (v === '' ? null : v),
    },
    setupComplete: {
      type: Boolean,
      default: false,
    },
    active: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// **Middleware: Convert Number to String before saving**
ShopInfoSchema.pre('save', function (next) {
  if (typeof this.subscriptionType === 'number') {
    this.subscriptionType = SubscriptionEnumMapping[this.subscriptionType]; // Convert number to string
  }
  this.modifiedDate = Date.now();
  next();
});

module.exports = mongoose.model('ShopInfo', ShopInfoSchema);
