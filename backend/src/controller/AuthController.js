const { loginService, validateOTPService } = require('../service/AuthService');

const loginController = async (req, res) => {
  try {
    const { mobileNumber } = req.body;

    // Call the login service
    const result = await loginService(mobileNumber);

    // Send the response with user details and OTP
    res.status(200).json({
      message: 'Login successful',
      user: result.user,
      otp: result.otp,
    });
  } catch (error) {
    console.error('Error in loginController:', error);

    // Handle specific errors
    if (error.message === 'Mobile number is required') {
      return res.status(400).json({ error: error.message });
    }
    if (error.message === 'User not found') {
      return res.status(404).json({ error: error.message });
    }

    // Handle generic errors
    res.status(500).json({ error: 'Internal server error' });
  }
};

// OTP Validation Controller
const validateOTPController = async (req, res) => {
  try {
    const { mobileNumber, otp } = req.body;
    const result = await validateOTPService(mobileNumber, parseInt(otp));

    res.status(200).json(result);
  } catch (error) {
    console.error('Error in validateOTPController:', error);
    return res
      .status(error.message === 'Invalid OTP' ? 400 : 404)
      .json({ error: error.message });
  }
};

module.exports = {
  loginController,
  validateOTPController,
};
