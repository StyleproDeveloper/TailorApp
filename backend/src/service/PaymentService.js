const Payment = require('../models/PaymentModel');
const { getNextSequenceValue } = require('./sequenceService');
const logger = require('../utils/logger');
const { default: mongoose } = require('mongoose');

/**
 * Get Payment model for a specific shop
 * @param {number} shop_id - Shop ID
 * @returns {Model} Payment model
 */
const getPaymentModel = (shop_id) => {
  const collectionName = `payment_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Payment.schema, collectionName)
  );
};

/**
 * Create a new payment
 * @param {Object} paymentData - Payment data
 * @param {number} shop_id - Shop ID
 * @returns {Promise<Object>} Created payment
 */
const createPaymentService = async (paymentData, shop_id) => {
  try {
    // Validate shop_id
    if (!shop_id || shop_id <= 0) {
      throw new Error('Invalid shop_id');
    }

    // Get payment model for this shop
    const PaymentModel = getPaymentModel(shop_id);

    // Generate payment ID
    const paymentId = await getNextSequenceValue('paymentId');

    // Verify order exists - use the same pattern as OrderService
    const Order = require('../models/OrderModel');
    const { default: mongoose } = require('mongoose');
    const getOrderModel = (shop_id) => {
      const collectionName = `order_${shop_id}`;
      return (
        mongoose.models[collectionName] ||
        mongoose.model(collectionName, Order.schema, collectionName)
      );
    };
    const OrderModel = getOrderModel(shop_id);
    const order = await OrderModel.findOne({ orderId: paymentData.orderId });
    if (!order) {
      throw new Error(`Order with ID ${paymentData.orderId} not found`);
    }

    // Create payment
    const payment = new PaymentModel({
      paymentId,
      shop_id,
      orderId: paymentData.orderId,
      paidAmount: paymentData.paidAmount,
      paymentDate: paymentData.paymentDate,
      paymentType: paymentData.paymentType || 'partial',
      notes: paymentData.notes || '',
      owner: paymentData.owner,
    });

    await payment.save();

    // Update order's paidAmount by summing all payments for this order
    const allPayments = await PaymentModel.find({ orderId: paymentData.orderId });
    const totalPaid = allPayments.reduce((sum, p) => sum + (p.paidAmount || 0), 0);
    
    // Also include advance received in the total paid amount
    const totalPaidAmount = totalPaid + (order.advancereceived || 0);
    
    await OrderModel.findOneAndUpdate(
      { orderId: paymentData.orderId },
      { $set: { paidAmount: totalPaidAmount } },
      { new: true }
    );

    logger.info('Payment created successfully', {
      shop_id,
      paymentId,
      orderId: paymentData.orderId,
      paidAmount: paymentData.paidAmount,
    });

    return payment;
  } catch (error) {
    logger.error('Error creating payment', {
      shop_id,
      error: error.message,
      stack: error.stack,
    });
    throw error;
  }
};

/**
 * Get all payments for an order
 * @param {number} shop_id - Shop ID
 * @param {number} orderId - Order ID
 * @returns {Promise<Array>} List of payments
 */
const getPaymentsByOrderService = async (shop_id, orderId) => {
  try {
    if (!shop_id || shop_id <= 0) {
      throw new Error('Invalid shop_id');
    }
    if (!orderId || orderId <= 0) {
      throw new Error('Invalid orderId');
    }

    const PaymentModel = getPaymentModel(shop_id);
    const payments = await PaymentModel.find({ orderId })
      .sort({ paymentDate: -1, createdAt: -1 })
      .lean();

    return payments;
  } catch (error) {
    logger.error('Error fetching payments by order', {
      shop_id,
      orderId,
      error: error.message,
    });
    throw error;
  }
};

/**
 * Get all payments for a shop
 * @param {number} shop_id - Shop ID
 * @param {Object} filters - Optional filters (pageNumber, pageSize)
 * @returns {Promise<Object>} Paginated payments
 */
const getAllPaymentsService = async (shop_id, filters = {}) => {
  try {
    if (!shop_id || shop_id <= 0) {
      throw new Error('Invalid shop_id');
    }

    const PaymentModel = getPaymentModel(shop_id);
    const pageNumber = parseInt(filters.pageNumber) || 1;
    const pageSize = parseInt(filters.pageSize) || 10;
    const skip = (pageNumber - 1) * pageSize;

    const query = {};
    if (filters.orderId) {
      query.orderId = parseInt(filters.orderId);
    }

    const [payments, total] = await Promise.all([
      PaymentModel.find(query)
        .sort({ paymentDate: -1, createdAt: -1 })
        .skip(skip)
        .limit(pageSize)
        .lean(),
      PaymentModel.countDocuments(query),
    ]);

    return {
      data: payments,
      pagination: {
        pageNumber,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  } catch (error) {
    logger.error('Error fetching all payments', {
      shop_id,
      error: error.message,
    });
    throw error;
  }
};

/**
 * Update a payment
 * @param {number} shop_id - Shop ID
 * @param {number} paymentId - Payment ID
 * @param {Object} updateData - Payment update data
 * @returns {Promise<Object>} Updated payment
 */
const updatePaymentService = async (shop_id, paymentId, updateData) => {
  try {
    if (!shop_id || shop_id <= 0) {
      throw new Error('Invalid shop_id');
    }
    if (!paymentId || paymentId <= 0) {
      throw new Error('Invalid paymentId');
    }

    const PaymentModel = getPaymentModel(shop_id);
    const payment = await PaymentModel.findOneAndUpdate(
      { paymentId },
      { $set: updateData },
      { new: true }
    );

    if (!payment) {
      throw new Error(`Payment with ID ${paymentId} not found`);
    }

    // Update order's paidAmount
    const Order = require('../models/OrderModel');
    const getOrderModel = (shop_id) => {
      const collectionName = `order_${shop_id}`;
      return (
        mongoose.models[collectionName] ||
        mongoose.model(collectionName, Order.schema, collectionName)
      );
    };
    const OrderModel = getOrderModel(shop_id);
    const order = await OrderModel.findOne({ orderId: payment.orderId });
    if (order) {
      const allPayments = await PaymentModel.find({ orderId: payment.orderId });
      const totalPaid = allPayments.reduce((sum, p) => sum + (p.paidAmount || 0), 0);
      const totalPaidAmount = totalPaid + (order.advancereceived || 0);
      
      await OrderModel.findOneAndUpdate(
        { orderId: payment.orderId },
        { $set: { paidAmount: totalPaidAmount } },
        { new: true }
      );
    }

    logger.info('Payment updated successfully', {
      shop_id,
      paymentId,
      orderId: payment.orderId,
    });

    return payment;
  } catch (error) {
    logger.error('Error updating payment', {
      shop_id,
      paymentId,
      error: error.message,
    });
    throw error;
  }
};

/**
 * Delete a payment
 * @param {number} shop_id - Shop ID
 * @param {number} paymentId - Payment ID
 * @returns {Promise<Object>} Deleted payment
 */
const deletePaymentService = async (shop_id, paymentId) => {
  try {
    if (!shop_id || shop_id <= 0) {
      throw new Error('Invalid shop_id');
    }
    if (!paymentId || paymentId <= 0) {
      throw new Error('Invalid paymentId');
    }

    const PaymentModel = getPaymentModel(shop_id);
    const payment = await PaymentModel.findOneAndDelete({ paymentId });

    if (!payment) {
      throw new Error(`Payment with ID ${paymentId} not found`);
    }

    // Update order's paidAmount
    const Order = require('../models/OrderModel');
    const getOrderModel = (shop_id) => {
      const collectionName = `order_${shop_id}`;
      return (
        mongoose.models[collectionName] ||
        mongoose.model(collectionName, Order.schema, collectionName)
      );
    };
    const OrderModel = getOrderModel(shop_id);
    const order = await OrderModel.findOne({ orderId: payment.orderId });
    if (order) {
      const allPayments = await PaymentModel.find({ orderId: payment.orderId });
      const totalPaid = allPayments.reduce((sum, p) => sum + (p.paidAmount || 0), 0);
      const totalPaidAmount = totalPaid + (order.advancereceived || 0);
      
      await OrderModel.findOneAndUpdate(
        { orderId: payment.orderId },
        { $set: { paidAmount: totalPaidAmount } },
        { new: true }
      );
    }

    logger.info('Payment deleted successfully', {
      shop_id,
      paymentId,
      orderId: payment.orderId,
    });

    return payment;
  } catch (error) {
    logger.error('Error deleting payment', {
      shop_id,
      paymentId,
      error: error.message,
    });
    throw error;
  }
};

module.exports = {
  createPaymentService,
  getPaymentsByOrderService,
  getAllPaymentsService,
  updatePaymentService,
  deletePaymentService,
};

