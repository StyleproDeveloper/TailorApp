const {
  uploadOrderMediaService,
  getOrderItemMediaService,
  getOrderMediaService,
  deleteOrderMediaService,
} = require('../service/OrderMediaService');
const { asyncHandler, CustomError } = require('../utils/error.handlers');
const logger = require('../utils/logger');

// Upload media
const uploadOrderMedia = asyncHandler(async (req, res) => {
  try {
    logger.info('📤 Media upload request received', {
      body: req.body,
      hasFile: !!req.file,
      fileSize: req.file?.size,
      fileName: req.file?.originalname,
      fileMimetype: req.file?.mimetype,
    });

    const { shopId, orderId, orderItemId, mediaType } = req.body;
    const file = req.file;

    if (!file) {
      logger.error('❌ No file uploaded');
      throw new CustomError('No file uploaded', 400);
    }

    if (!shopId || !orderId || !orderItemId || !mediaType) {
      logger.error('❌ Missing required fields', {
        shopId: !!shopId,
        orderId: !!orderId,
        orderItemId: !!orderItemId,
        mediaType: !!mediaType,
      });
      throw new CustomError('Shop ID, Order ID, Order Item ID, and Media Type are required', 400);
    }

    const owner = req.body.owner || null;

    logger.info('📤 Calling uploadOrderMediaService', {
      shopId: Number(shopId),
      orderId: Number(orderId),
      orderItemId: Number(orderItemId),
      mediaType,
      owner,
    });

    const media = await uploadOrderMediaService(
      Number(shopId),
      Number(orderId),
      Number(orderItemId),
      file,
      mediaType,
      owner
    );

    logger.info('✅ Media uploaded successfully', {
      orderMediaId: media.orderMediaId,
      mediaUrl: media.mediaUrl,
    });

    res.status(201).json({
      success: true,
      message: 'Media uploaded successfully',
      data: media,
    });
  } catch (error) {
    logger.error('❌ Error in uploadOrderMedia controller', {
      error: error.message,
      stack: error.stack,
      body: req.body,
      hasFile: !!req.file,
    });
    throw error;
  }
});

// Get media for an order item
const getOrderItemMedia = asyncHandler(async (req, res) => {
  try {
    const { shopId, orderId, orderItemId } = req.params;

    if (!shopId || !orderId || !orderItemId) {
      throw new CustomError('Shop ID, Order ID, and Order Item ID are required', 400);
    }

    const media = await getOrderItemMediaService(
      Number(shopId),
      Number(orderId),
      Number(orderItemId)
    );

    res.status(200).json({
      success: true,
      data: media,
    });
  } catch (error) {
    logger.error('Error in getOrderItemMedia controller', error);
    throw error;
  }
});

// Get all media for an order
const getOrderMedia = asyncHandler(async (req, res) => {
  try {
    const { shopId, orderId } = req.params;

    if (!shopId || !orderId) {
      throw new CustomError('Shop ID and Order ID are required', 400);
    }

    const media = await getOrderMediaService(Number(shopId), Number(orderId));

    res.status(200).json({
      success: true,
      data: media,
    });
  } catch (error) {
    logger.error('Error in getOrderMedia controller', error);
    throw error;
  }
});

// Delete media
const deleteOrderMedia = asyncHandler(async (req, res) => {
  try {
    const { shopId, orderMediaId } = req.params;

    if (!shopId || !orderMediaId) {
      throw new CustomError('Shop ID and Order Media ID are required', 400);
    }

    const result = await deleteOrderMediaService(Number(shopId), Number(orderMediaId));

    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in deleteOrderMedia controller', error);
    throw error;
  }
});

module.exports = {
  uploadOrderMedia,
  getOrderItemMedia,
  getOrderMedia,
  deleteOrderMedia,
};

