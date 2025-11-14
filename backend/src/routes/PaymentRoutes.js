const express = require('express');
const router = express.Router();
const {
  createPayment,
  getPaymentsByOrder,
  getAllPayments,
  updatePayment,
  deletePayment,
} = require('../controller/PaymentController');
const {
  createPaymentSchema,
  updatePaymentSchema,
} = require('../validations/PaymentValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @route   POST /payments/:shop_id
 * @desc    Create a new payment
 * @access  Private
 */
router.post(
  '/:shop_id',
  validateRequest(createPaymentSchema),
  createPayment
);

/**
 * @route   GET /payments/:shop_id/order/:orderId
 * @desc    Get all payments for a specific order
 * @access  Private
 */
router.get(
  '/:shop_id/order/:orderId',
  getPaymentsByOrder
);

/**
 * @route   GET /payments/:shop_id
 * @desc    Get all payments for a shop (with pagination)
 * @access  Private
 */
router.get(
  '/:shop_id',
  getAllPayments
);

/**
 * @route   PATCH /payments/:shop_id/:paymentId
 * @desc    Update a payment
 * @access  Private
 */
router.patch(
  '/:shop_id/:paymentId',
  validateRequest(updatePaymentSchema),
  updatePayment
);

/**
 * @route   DELETE /payments/:shop_id/:paymentId
 * @desc    Delete a payment
 * @access  Private
 */
router.delete(
  '/:shop_id/:paymentId',
  deletePayment
);

module.exports = router;

