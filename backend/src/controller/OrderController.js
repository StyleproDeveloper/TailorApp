const {
  createOrderService,
  getAllOrdersService,
  updateOrderService,
  updateOrderItemDeliveryStatusService,
} = require('../service/OrderService');
const { asyncHandler, CustomError } = require('../utils/error.handlers');
const logger = require('../utils/logger');

const createOrder = asyncHandler(async (req, res) => {
  const { shop_id } = req?.body?.Order;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }
  
  const response = await createOrderService(req?.body, shop_id);
  res.status(201).json({
    success: true,
    message: 'Order Created Successfully',
    data: response,
  });
});

const getAllOrders = asyncHandler(async (req, res) => {
  const { shop_id } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }
  
  const response = await getAllOrdersService(shop_id, req?.query);
  res.status(200).json({
    success: true,
    ...response,
  });
});

const updateOrder = asyncHandler(async (req, res) => {
  const { shop_id, id } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }
  
  // Parse orderId to number
  const orderId = parseInt(id, 10);
  if (isNaN(orderId)) {
    throw new CustomError('Invalid order ID', 400);
  }
  
  const response = await updateOrderService(orderId, req.body, parseInt(shop_id, 10));
  if (!response) {
    throw new CustomError('Order not found', 404);
  }
  
  res.status(200).json({
    success: true,
    message: 'Order updated successfully',
    data: response,
  });
});

const updateOrderItemDeliveryStatus = asyncHandler(async (req, res) => {
  const { shop_id, orderItemId } = req.params;
  if (!shop_id) {
    throw new CustomError('Shop ID is required', 400);
  }
  if (!orderItemId) {
    throw new CustomError('Order Item ID is required', 400);
  }
  
  const response = await updateOrderItemDeliveryStatusService(shop_id, orderItemId, req.body);
  if (!response) {
    throw new CustomError('Order item not found', 404);
  }
  
  res.status(200).json({
    success: true,
    message: 'Order item delivery status updated successfully',
    data: response,
  });
});

module.exports = {
  createOrder,
  getAllOrders,
  updateOrder,
  updateOrderItemDeliveryStatus,
};
