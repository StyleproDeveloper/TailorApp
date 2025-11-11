const OrderMedia = require('../models/OrderMediaModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs').promises;
const logger = require('../utils/logger');

// Get dynamic OrderMedia model based on shopId
const getOrderMediaModel = (shopId) => {
  const collectionName = `ordermedia_${shopId}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, OrderMedia.schema, collectionName)
  );
};

// Upload media file
const uploadOrderMediaService = async (shopId, orderId, orderItemId, file, mediaType, owner) => {
  try {
    if (!shopId || !orderId || !orderItemId) {
      throw new Error('Shop ID, Order ID, and Order Item ID are required');
    }

    const shopExists = await isShopExists(shopId);
    if (!shopExists) {
      throw new Error(`Shop with ID ${shopId} does not exist`);
    }

    // Validate media type
    if (!['image', 'audio'].includes(mediaType)) {
      throw new Error('Media type must be either "image" or "audio"');
    }

    // Create uploads directory if it doesn't exist
    const uploadsDir = path.join(__dirname, '../../uploads', `shop_${shopId}`, `order_${orderId}`);
    await fs.mkdir(uploadsDir, { recursive: true });

    // Generate unique filename
    // Handle case where originalname might be missing or empty
    const originalName = file.originalname || `file_${Date.now()}`;
    const fileExt = path.extname(originalName) || (mediaType === 'image' ? '.jpg' : '.mp3');
    const fileName = `${mediaType}_${Date.now()}_${Math.random().toString(36).substring(7)}${fileExt}`;
    const filePath = path.join(uploadsDir, fileName);
    
    logger.info('📁 Saving file', {
      originalName,
      fileName,
      filePath,
      fileSize: file.size,
      bufferSize: file.buffer?.length,
    });

    // Save file to disk
    await fs.writeFile(filePath, file.buffer);

    // Generate media URL (relative path from uploads directory)
    const mediaUrl = `/uploads/shop_${shopId}/order_${orderId}/${fileName}`;

    // Get next sequence value for orderMediaId
    const orderMediaId = await getNextSequenceValue('orderMediaId', shopId);

    // Get dynamic model
    const OrderMediaModel = getOrderMediaModel(shopId);

    // Create media record
    const mediaRecord = new OrderMediaModel({
      orderMediaId,
      orderId: Number(orderId),
      orderItemId: Number(orderItemId),
      shopId: Number(shopId),
      mediaType,
      mediaUrl,
      fileName: file.originalname,
      fileSize: file.size,
      mimeType: file.mimetype,
      owner: owner || null,
    });

    await mediaRecord.save();

    logger.info('Order media uploaded successfully', {
      shopId,
      orderId,
      orderItemId,
      orderMediaId,
      mediaType,
      fileName: file.originalname,
    });

    return mediaRecord;
  } catch (error) {
    logger.error('Error uploading order media', error);
    throw error;
  }
};

// Get all media for an order item
const getOrderItemMediaService = async (shopId, orderId, orderItemId) => {
  try {
    if (!shopId || !orderId || !orderItemId) {
      throw new Error('Shop ID, Order ID, and Order Item ID are required');
    }

    const OrderMediaModel = getOrderMediaModel(shopId);

    const media = await OrderMediaModel.find({
      orderId: Number(orderId),
      orderItemId: Number(orderItemId),
    }).sort({ createdAt: -1 });

    return media;
  } catch (error) {
    logger.error('Error fetching order item media', error);
    throw error;
  }
};

// Get all media for an order
const getOrderMediaService = async (shopId, orderId) => {
  try {
    if (!shopId || !orderId) {
      throw new Error('Shop ID and Order ID are required');
    }

    const OrderMediaModel = getOrderMediaModel(shopId);

    const media = await OrderMediaModel.find({
      orderId: Number(orderId),
    }).sort({ orderItemId: 1, createdAt: -1 });

    return media;
  } catch (error) {
    logger.error('Error fetching order media', error);
    throw error;
  }
};

// Delete media
const deleteOrderMediaService = async (shopId, orderMediaId) => {
  try {
    if (!shopId || !orderMediaId) {
      throw new Error('Shop ID and Order Media ID are required');
    }

    const OrderMediaModel = getOrderMediaModel(shopId);

    const media = await OrderMediaModel.findOne({ orderMediaId: Number(orderMediaId) });

    if (!media) {
      throw new Error('Media not found');
    }

    // Delete file from disk
    const filePath = path.join(__dirname, '../../', media.mediaUrl);
    try {
      await fs.unlink(filePath);
    } catch (fileError) {
      logger.warn('Error deleting media file', { filePath, error: fileError.message });
      // Continue even if file deletion fails
    }

    // Delete record from database
    await OrderMediaModel.deleteOne({ orderMediaId: Number(orderMediaId) });

    logger.info('Order media deleted successfully', { shopId, orderMediaId });

    return { success: true, message: 'Media deleted successfully' };
  } catch (error) {
    logger.error('Error deleting order media', error);
    throw error;
  }
};

module.exports = {
  uploadOrderMediaService,
  getOrderItemMediaService,
  getOrderMediaService,
  deleteOrderMediaService,
  getOrderMediaModel,
};

