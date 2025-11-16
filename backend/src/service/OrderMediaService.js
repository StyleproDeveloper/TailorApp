const OrderMedia = require('../models/OrderMediaModel');
const ShopInfo = require('../models/ShopModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { uploadToS3, deleteFromS3, parseS3Url } = require('../utils/s3Service');
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

    // Get shop information to retrieve S3 bucket name
    const shop = await ShopInfo.findOne({ shop_id: Number(shopId) });
    if (!shop) {
      throw new Error(`Shop with ID ${shopId} not found`);
    }

    // Generate unique filename
    const originalName = file.originalname || `file_${Date.now()}`;
    const fileExt = path.extname(originalName) || (mediaType === 'image' ? '.jpg' : '.mp3');
    const fileName = `${mediaType}_${Date.now()}_${Math.random().toString(36).substring(7)}${fileExt}`;
    
    let mediaUrl;

    // Upload to S3 if bucket exists, otherwise fallback to local storage
    if (shop.s3BucketName && process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
      try {
        // S3 key path: order_{orderId}/{fileName}
        const s3Key = `order_${orderId}/${fileName}`;
        
        logger.info('📤 Uploading file to S3', {
          bucketName: shop.s3BucketName,
          s3Key,
          originalName,
          fileSize: file.size,
          contentType: file.mimetype,
        });

        // Upload to S3
        mediaUrl = await uploadToS3(
          shop.s3BucketName,
          s3Key,
          file.buffer,
          file.mimetype || (mediaType === 'image' ? 'image/jpeg' : 'audio/mpeg'),
          {
            shopId: shopId.toString(),
            orderId: orderId.toString(),
            orderItemId: orderItemId.toString(),
            mediaType,
            originalName: file.originalname || fileName,
          }
        );

        logger.info('✅ File uploaded to S3 successfully', { mediaUrl });
      } catch (s3Error) {
        logger.error('Error uploading to S3, falling back to local storage', s3Error, {
          shopId,
          bucketName: shop.s3BucketName,
        });
        // Fallback to local storage if S3 upload fails
        const uploadsDir = path.join(__dirname, '../../uploads', `shop_${shopId}`, `order_${orderId}`);
        await fs.mkdir(uploadsDir, { recursive: true });
        const filePath = path.join(uploadsDir, fileName);
        await fs.writeFile(filePath, file.buffer);
        mediaUrl = `/uploads/shop_${shopId}/order_${orderId}/${fileName}`;
      }
    } else {
      // Fallback to local storage if S3 is not configured
      logger.info('📁 S3 not configured, using local storage', { shopId });
      const uploadsDir = path.join(__dirname, '../../uploads', `shop_${shopId}`, `order_${orderId}`);
      await fs.mkdir(uploadsDir, { recursive: true });
      const filePath = path.join(uploadsDir, fileName);
      await fs.writeFile(filePath, file.buffer);
      mediaUrl = `/uploads/shop_${shopId}/order_${orderId}/${fileName}`;
    }

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
      fileName: file.originalname || originalName,
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
      mediaUrl,
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

    // Check if media URL is S3 URL or local path
    const s3UrlInfo = parseS3Url(media.mediaUrl);
    
    if (s3UrlInfo) {
      // Delete from S3
      try {
        await deleteFromS3(s3UrlInfo.bucketName, s3UrlInfo.key);
        logger.info('File deleted from S3', { bucketName: s3UrlInfo.bucketName, key: s3UrlInfo.key });
      } catch (s3Error) {
        logger.warn('Error deleting file from S3', { 
          bucketName: s3UrlInfo.bucketName, 
          key: s3UrlInfo.key, 
          error: s3Error.message 
        });
        // Continue even if S3 deletion fails
      }
    } else {
      // Delete from local storage
      const filePath = path.join(__dirname, '../../', media.mediaUrl);
      try {
        await fs.unlink(filePath);
        logger.info('File deleted from local storage', { filePath });
      } catch (fileError) {
        logger.warn('Error deleting media file from local storage', { 
          filePath, 
          error: fileError.message 
        });
        // Continue even if file deletion fails
      }
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

