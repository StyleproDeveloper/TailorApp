const express = require('express');
const router = express.Router();
const {
  loginController,
  validateOTPController,
} = require('../controller/AuthController');

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login using mobile number
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               mobileNumber:
 *                 type: string
 *                 description: User's mobile number
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user:
 *                   type: object
 *                   description: User details
 *                 otp:
 *                   type: number
 *                   description: Generated 4-digit OTP
 *       404:
 *         description: User not found
 *       500:
 *         description: Internal server error
 */
router.post('/login', loginController);

/**
 * @swagger
 * /auth/validate-otp:
 *   post:
 *     summary: Validate OTP
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               mobileNumber:
 *                 type: string
 *               otp:
 *                 type: number
 *     responses:
 *       200:
 *         description: OTP validated successfully
 *       400:
 *         description: Invalid OTP
 *       404:
 *         description: OTP expired or user not found
 */
router.post('/validate-otp', validateOTPController);

module.exports = router;
