const Gallery = require('../models/GalleryModel');
const ShopInfo = require('../models/ShopModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { uploadToS3, deleteFromS3, parseS3Url } = require('../utils/s3Service');
const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs').promises;
const logger = require('../utils/logger');

// Get dynamic Gallery model based on shopId
const getGalleryModel = (shopId) => {
  const collectionName = `gallery_${shopId}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Gallery.schema, collectionName)
  );
};

// Upload gallery image
const uploadGalleryImageService = async (shopId, file, owner) => {
  try {
    if (!shopId) {
      throw new Error('Shop ID is required');
    }

    const shopExists = await isShopExists(shopId);
    if (!shopExists) {
      throw new Error(`Shop with ID ${shopId} does not exist`);
    }

    // Get shop information to retrieve S3 bucket name
    const shop = await ShopInfo.findOne({ shop_id: Number(shopId) });
    if (!shop) {
      throw new Error(`Shop with ID ${shopId} not found`);
    }

    // Generate unique filename
    const originalName = file.originalname || `file_${Date.now()}`;
    const fileExt = path.extname(originalName) || '.jpg';
    const fileName = `gallery_${Date.now()}_${Math.random().toString(36).substring(7)}${fileExt}`;
    
    // Determine content type
    let contentType = file.mimetype;
    if (!contentType) {
      const ext = path.extname(originalName).toLowerCase();
      const mimeMap = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.heic': 'image/heic',
        '.heif': 'image/heic',
        '.bmp': 'image/bmp',
        '.tiff': 'image/tiff',
        '.tif': 'image/tiff',
        '.ico': 'image/x-icon',
        '.svg': 'image/svg+xml',
      };
      contentType = mimeMap[ext] || 'image/jpeg';
    }
    
    let imageUrl;

    // Upload to S3 if bucket exists, otherwise fallback to local storage
    if (shop.s3BucketName && process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
      try {
        // S3 key path: gallery/{fileName}
        const s3Key = `gallery/${fileName}`;
        
        logger.info('📤 Uploading gallery image to S3', {
          bucketName: shop.s3BucketName,
          s3Key,
          originalName,
          fileSize: file.size,
          contentType: contentType,
        });

        // Upload to S3
        imageUrl = await uploadToS3(
          shop.s3BucketName,
          s3Key,
          file.buffer,
          contentType,
          {
            shopId: shopId.toString(),
            originalName: file.originalname || fileName,
          }
        );

        logger.info('✅ Gallery image uploaded to S3 successfully', { imageUrl });
      } catch (s3Error) {
        logger.error('Error uploading gallery image to S3, falling back to local storage', s3Error, {
          shopId,
          bucketName: shop.s3BucketName,
        });
        // Fallback to local storage if S3 upload fails
        const uploadsDir = path.join(__dirname, '../../uploads', `shop_${shopId}`, 'gallery');
        await fs.mkdir(uploadsDir, { recursive: true });
        const filePath = path.join(uploadsDir, fileName);
        await fs.writeFile(filePath, file.buffer);
        imageUrl = `/uploads/shop_${shopId}/gallery/${fileName}`;
      }
    } else {
      // Fallback to local storage if S3 is not configured
      logger.info('📁 S3 not configured, using local storage for gallery', { shopId });
      const uploadsDir = path.join(__dirname, '../../uploads', `shop_${shopId}`, 'gallery');
      await fs.mkdir(uploadsDir, { recursive: true });
      const filePath = path.join(uploadsDir, fileName);
      await fs.writeFile(filePath, file.buffer);
      imageUrl = `/uploads/shop_${shopId}/gallery/${fileName}`;
    }

    const GalleryModel = getGalleryModel(shopId);
    const galleryId = await getNextSequenceValue('galleryId', shopId);

    const galleryImage = new GalleryModel({
      galleryId,
      shopId: Number(shopId),
      imageUrl,
      fileName: file.originalname || originalName,
      fileSize: file.size,
      mimeType: contentType,
      owner: owner || null,
    });

    await galleryImage.save();
    return galleryImage;
  } catch (error) {
    logger.error('Error uploading gallery image', error);
    throw error;
  }
};

// Get all gallery images for a shop
const getGalleryImagesService = async (shopId, pageNumber = 1, pageSize = 50) => {
  try {
    if (!shopId) {
      throw new Error('Shop ID is required');
    }

    const GalleryModel = getGalleryModel(shopId);
    const skip = (pageNumber - 1) * pageSize;

    const images = await GalleryModel.find({ shopId: Number(shopId) })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(pageSize)
      .lean();

    const total = await GalleryModel.countDocuments({ shopId: Number(shopId) });

    return {
      images,
      total,
      pageNumber,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  } catch (error) {
    logger.error('Error fetching gallery images', error);
    throw error;
  }
};

// Delete gallery image
const deleteGalleryImageService = async (shopId, galleryId) => {
  try {
    if (!shopId || !galleryId) {
      throw new Error('Shop ID and Gallery ID are required');
    }

    const GalleryModel = getGalleryModel(shopId);
    const image = await GalleryModel.findOne({ galleryId: Number(galleryId) });

    if (!image) {
      throw new Error('Gallery image not found');
    }

    // Check if image URL is S3 URL or local path
    const s3UrlInfo = parseS3Url(image.imageUrl);
    
    if (s3UrlInfo) {
      // Delete from S3
      try {
        await deleteFromS3(s3UrlInfo.bucketName, s3UrlInfo.key);
        logger.info('Gallery image deleted from S3', { bucketName: s3UrlInfo.bucketName, key: s3UrlInfo.key });
      } catch (s3Error) {
        logger.warn('Error deleting gallery image from S3', { 
          bucketName: s3UrlInfo.bucketName, 
          key: s3UrlInfo.key, 
          error: s3Error.message 
        });
        // Continue even if S3 deletion fails
      }
    } else {
      // Delete from local storage
      const filePath = path.join(__dirname, '../../', image.imageUrl);
      try {
        await fs.unlink(filePath);
        logger.info('Gallery image deleted from local storage', { filePath });
      } catch (fileError) {
        logger.warn('Error deleting gallery image from local storage', { 
          filePath, 
          error: fileError.message 
        });
        // Continue even if file deletion fails
      }
    }

    // Delete record from database
    await GalleryModel.deleteOne({ galleryId: Number(galleryId) });

    logger.info('Gallery image deleted successfully', { shopId, galleryId });

    return { success: true, message: 'Gallery image deleted successfully' };
  } catch (error) {
    logger.error('Error deleting gallery image', error);
    throw error;
  }
};

module.exports = {
  uploadGalleryImageService,
  getGalleryImagesService,
  deleteGalleryImageService,
  getGalleryModel,
};

