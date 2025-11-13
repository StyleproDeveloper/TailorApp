const { loginService, validateOTPService } = require('../service/AuthService');
const { asyncHandler } = require('../utils/error.handlers');
const { CustomError } = require('../utils/error.handlers');
const logger = require('../utils/logger');

const loginController = asyncHandler(async (req, res) => {
  const { mobileNumber } = req.body;

  if (!mobileNumber) {
    throw new CustomError('Mobile number is required', 400);
  }

  try {
    // Call the login service
    const result = await loginService(mobileNumber);

    // Send the response with user details and OTP
    res.status(200).json({
      message: 'Login successful',
      user: result.user,
      otp: result.otp,
    });
  } catch (error) {
    logger.error('Error in loginController', {
      error: error.message,
      stack: error.stack,
      mobileNumber: mobileNumber ? mobileNumber.substring(0, 4) + '****' : 'N/A',
    });

    // Re-throw to let errorHandler handle it
    throw error;
  }
});

// OTP Validation Controller
const validateOTPController = asyncHandler(async (req, res) => {
  const { mobileNumber, otp } = req.body;

  if (!mobileNumber || !otp) {
    throw new CustomError('Mobile number and OTP are required', 400);
  }

  try {
    const result = await validateOTPService(mobileNumber, parseInt(otp));
    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in validateOTPController', {
      error: error.message,
      stack: error.stack,
      mobileNumber: mobileNumber ? mobileNumber.substring(0, 4) + '****' : 'N/A',
    });

    // Re-throw to let errorHandler handle it
    throw error;
  }
});

module.exports = {
  loginController,
  validateOTPController,
};
