const User = require('../models/UserModel');
const Role = require('../models/RoleModel');
const ShopInfo = require('../models/ShopModel');
const mongoose = require('mongoose');
const otpStore = new Map();
const logger = require('../utils/logger');

// Generate a 4-digit OTP
const generateOTP = () => {
  return Math.floor(1000 + Math.random() * 9000);
};

// Login service
const loginService = async (mobileNumber) => {
  try {
    // Check if mobile number is provided
    if (!mobileNumber) {
      throw new Error('Mobile number is required');
    }

    // Normalize mobile number: remove spaces, dashes, and other non-digit characters except leading +
    let normalizedMobile = mobileNumber.toString().trim();
    
    // Try exact match first
    let user = await User.findOne({ mobile: normalizedMobile });
    
    // If not found, try with different formats
    if (!user) {
      // Try with + prefix
      user = await User.findOne({ mobile: `+${normalizedMobile}` });
    }
    
    if (!user) {
      // Try without country code (last 10 digits)
      const last10Digits = normalizedMobile.slice(-10);
      user = await User.findOne({ mobile: last10Digits });
    }
    
    if (!user) {
      // Try with country code (if it starts with 91, try with +91)
      if (normalizedMobile.startsWith('91') && normalizedMobile.length > 10) {
        user = await User.findOne({ mobile: `+${normalizedMobile}` });
      }
    }

    // Log for debugging
    logger.debug('Login attempt', {
      received: mobileNumber,
      normalized: normalizedMobile,
      userFound: user ? 'Yes' : 'No',
    });

    // If user does not exist, throw an error
    if (!user) {
      throw new Error('User not found');
    }

    // Check if the shop is active before generating OTP
    if (user.shopId) {
      const shop = await ShopInfo.findOne({ shop_id: user.shopId });
      if (!shop) {
        throw new Error('Shop not found for this user');
      }
      if (shop.active === false) {
        throw new Error('This shop account is inactive. Please contact support.');
      }
    }

    // Generate a 4-digit OTP
    const otp = generateOTP();
    otpStore.set(mobileNumber, otp);

    // Return user details and OTP
    return {
      otp,
    };
  } catch (error) {
    throw error;
  }
};

// OTP Validation Service
const validateOTPService = async (mobileNumber, otp) => {
  try {
    if (!mobileNumber || !otp) {
      throw new Error('Mobile number and OTP are required');
    }

    // Retrieve stored OTP
    const storedOTP = otpStore.get(mobileNumber);

    logger.debug('OTP validation', { hasStoredOTP: !!storedOTP });

    if (!storedOTP) {
      throw new Error('OTP expired or not found');
    }

    if (storedOTP !== otp) {
      throw new Error('Invalid OTP');
    }

    // Remove OTP after successful validation
    otpStore.delete(mobileNumber);

    // Normalize mobile number
    let normalizedMobile = mobileNumber.toString().trim();
    
    // Retrieve user details - try multiple formats
    let user = await User.findOne({ mobile: normalizedMobile });
    
    if (!user) {
      // Try with + prefix
      user = await User.findOne({ mobile: `+${normalizedMobile}` });
    }
    
    if (!user) {
      // Try without country code (last 10 digits)
      const last10Digits = normalizedMobile.slice(-10);
      user = await User.findOne({ mobile: last10Digits });
    }
    
    if (!user) {
      // Try with country code format
      if (normalizedMobile.startsWith('91') && normalizedMobile.length > 10) {
        user = await User.findOne({ mobile: `+${normalizedMobile}` });
      }
    }

    if (!user) {
      throw new Error('User not found');
    }

    // Check if the shop is active and trial status
    let shop = null;
    let isTrialExpired = false;
    let trialEndDate = null;
    
    if (user.shopId) {
      shop = await ShopInfo.findOne({ shop_id: user.shopId });
      if (!shop) {
        throw new Error('Shop not found for this user');
      }
      if (shop.active === false) {
        throw new Error('This shop account is inactive. Please contact support.');
      }
      
      // Check if trial has expired
      // For Trial subscriptions, check both trialEndDate and subscriptionEndDate
      // (older shops might only have subscriptionEndDate)
      if (shop.subscriptionType === 'Trial') {
        const now = new Date();
        let endDate = null;
        
        // Prefer trialEndDate, but fall back to subscriptionEndDate if trialEndDate is not set
        if (shop.trialEndDate) {
          endDate = new Date(shop.trialEndDate);
          trialEndDate = shop.trialEndDate;
        } else if (shop.subscriptionEndDate) {
          endDate = new Date(shop.subscriptionEndDate);
          trialEndDate = shop.subscriptionEndDate;
        }
        
        if (endDate) {
          isTrialExpired = now > endDate;
          
          logger.info('Trial status check', {
            shopId: shop.shop_id,
            subscriptionType: shop.subscriptionType,
            trialEndDate: shop.trialEndDate,
            subscriptionEndDate: shop.subscriptionEndDate,
            endDateUsed: endDate.toISOString(),
            isTrialExpired,
            currentDate: now.toISOString(),
            daysPast: Math.floor((now - endDate) / (1000 * 60 * 60 * 24)),
          });
        } else {
          // If no end date is set, log a warning but don't block login
          logger.warn('Trial subscription has no end date', {
            shopId: shop.shop_id,
            subscriptionType: shop.subscriptionType,
          });
        }
      }
    }

    // Fetch role name from Role model
    let roleName = null;
    if (user.roleId && user.shopId) {
      try {
        const Role = require('../models/RoleModel');
        const roleCollectionName = `role_${user.shopId}`;
        const RoleModel = mongoose.model(roleCollectionName, Role.schema, roleCollectionName);
        const role = await RoleModel.findOne({ roleId: user.roleId });
        if (role) {
          roleName = role.name;
        }
      } catch (error) {
        logger.warn('Could not fetch role name', { error: error.message, roleId: user.roleId, shopId: user.shopId });
      }
    }

    return {
      message: 'OTP validated successfully',
      user: {
        id: user._id,
        userId: user.userId,
        shopId: user.shopId,
        name: user.name,
        mobileNumber: user.mobile,
        email: user.email,
        roleId: user.roleId,
        roleName: roleName,
        branchId: user.branchId,
        secondaryMobile: user.secondaryMobile,
        addressLine1: user.addressLine1,
        street: user.street,
        city: user.city,
        postalCode: user.postalCode,
      },
      // Include trial status information
      subscriptionStatus: {
        subscriptionType: shop?.subscriptionType || null,
        isTrialExpired,
        trialEndDate: trialEndDate ? new Date(trialEndDate).toISOString() : null,
        requiresSubscription: isTrialExpired && shop?.subscriptionType === 'Trial',
      },
    };
  } catch (error) {
    throw error;
  }
};

// const validateOTPService = async (mobileNumber, otp) => {
//   try {
//     if (!mobileNumber || !otp) {
//       throw new Error('Mobile number and OTP are required');
//     }

//     // Retrieve stored OTP
//     const storedOTP = otpStore.get(mobileNumber);
//     console.log('storedOTP', storedOTP);

//     if (!storedOTP) {
//       throw new Error('OTP expired or not found');
//     }

//     if (storedOTP !== otp) {
//       throw new Error('Invalid OTP');
//     }

//     // Remove OTP after successful validation
//     otpStore.delete(mobileNumber);

//     // Retrieve user details with their shopId
//     const user = await User.findOne({ mobile: mobileNumber });
//     console.log('user', user);

//     if (!user) {
//       throw new Error('User not found');
//     }

//     // Get the user's shopId
//     const shopId = user.shopId;
//     if (!shopId) {
//       throw new Error('User is not associated with any shop');
//     }

//     // Construct the role name pattern (role_<shop_id>)
//     const roleName = `role_${shopId}`;
//     const roleId = user?.roleId;
//     console.log(`Looking for role: ${roleName} with roleId: ${roleId}`);

//     // Find the specific role
//     const role = await Role.findOne({
//       name: roleName,
//       roleId: roleId,
//     });

//     console.log('Matched role:', role);

//     if (!role) {
//       throw new Error('Role not found for this user and shop combination');
//     }

//     // Process roles to return only true permissions
//     const formattedRoles = role?.map((role) => {
//       const permissions = {};
//       for (const [key, value] of Object.entries(role.toObject())) {
//         if (typeof value === 'boolean' && value) {
//           permissions[key] = value;
//         }
//       }

//       return {
//         id: role._id,
//         roleId: role.roleId,
//         name: role.name,
//         permissions: permissions,
//       };
//     });

//     return {
//       message: 'OTP validated successfully',
//       user: {
//         id: user?._id,
//         userId: user?.userId,
//         shopId: user?.shopId,
//         name: user?.name,
//         mobileNumber: user?.mobile,
//         email: user?.email,
//         roles: formattedRoles,
//         branchId: user?.branchId,
//         secondaryMobile: user?.secondaryMobile,
//         addressLine1: user?.addressLine1,
//         street: user?.street,
//         city: user?.city,
//         postalCode: user?.postalCode,
//       },
//     };
//   } catch (error) {
//     throw error;
//   }
// };

module.exports = {
  loginService,
  validateOTPService,
};
