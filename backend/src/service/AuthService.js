const User = require('../models/UserModel');
const Role = require('../models/RoleModel');
const otpStore = new Map();

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

    // Find the user by mobile number
    const user = await User.findOne({ mobile: mobileNumber });

    // If user does not exist, throw an error
    if (!user) {
      throw new Error('User not found');
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

    console.log('storedOTP', storedOTP);

    if (!storedOTP) {
      throw new Error('OTP expired or not found');
    }

    if (storedOTP !== otp) {
      throw new Error('Invalid OTP');
    }

    // Remove OTP after successful validation
    otpStore.delete(mobileNumber);

    // Retrieve user details
    const user = await User.findOne({ mobile: mobileNumber });

    if (!user) {
      throw new Error('User not found');
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
        role: user.role,
        branchId: user.branchId,
        secondaryMobile: user.secondaryMobile,
        addressLine1: user.addressLine1,
        street: user.street,
        city: user.city,
        postalCode: user.postalCode,
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
