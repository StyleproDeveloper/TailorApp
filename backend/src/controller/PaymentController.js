const {
  createPaymentService,
  getPaymentsByOrderService,
  getAllPaymentsService,
  updatePaymentService,
  deletePaymentService,
} = require('../service/PaymentService');
const { asyncHandler, CustomError } = require('../utils/error.handlers');
const logger = require('../utils/logger');

const createPayment = asyncHandler(async (req, res) => {
  const { shop_id } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }

  const response = await createPaymentService(req.body, shop_id);
  res.status(201).json({
    success: true,
    message: 'Payment created successfully',
    data: response,
  });
});

const getPaymentsByOrder = asyncHandler(async (req, res) => {
  const { shop_id, orderId } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }
  if (!orderId) {
    throw new CustomError('Order ID is required', 400);
  }

  const response = await getPaymentsByOrderService(shop_id, orderId);
  res.status(200).json({
    success: true,
    data: response,
  });
});

const getAllPayments = asyncHandler(async (req, res) => {
  const { shop_id } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }

  const response = await getAllPaymentsService(shop_id, req.query);
  res.status(200).json({
    success: true,
    ...response,
  });
});

const updatePayment = asyncHandler(async (req, res) => {
  const { shop_id, paymentId } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }
  if (!paymentId) {
    throw new CustomError('Payment ID is required', 400);
  }

  const response = await updatePaymentService(shop_id, paymentId, req.body);
  if (!response) {
    throw new CustomError('Payment not found', 404);
  }

  res.status(200).json({
    success: true,
    message: 'Payment updated successfully',
    data: response,
  });
});

const deletePayment = asyncHandler(async (req, res) => {
  const { shop_id, paymentId } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }
  if (!paymentId) {
    throw new CustomError('Payment ID is required', 400);
  }

  const response = await deletePaymentService(shop_id, paymentId);
  if (!response) {
    throw new CustomError('Payment not found', 404);
  }

  res.status(200).json({
    success: true,
    message: 'Payment deleted successfully',
    data: response,
  });
});

module.exports = {
  createPayment,
  getPaymentsByOrder,
  getAllPayments,
  updatePayment,
  deletePayment,
};

