const {
  uploadGalleryImageService,
  getGalleryImagesService,
  deleteGalleryImageService,
} = require('../service/GalleryService');
const { asyncHandler, CustomError } = require('../utils/error.handlers');
const logger = require('../utils/logger');

// Upload gallery image
const uploadGalleryImage = asyncHandler(async (req, res) => {
  try {
    logger.info('📤 Gallery image upload request received', {
      body: req.body,
      hasFile: !!req.file,
      fileSize: req.file?.size,
      fileName: req.file?.originalname,
      fileMimetype: req.file?.mimetype,
    });

    const { shopId } = req.body;
    const file = req.file;

    if (!file) {
      logger.error('❌ No file uploaded');
      throw new CustomError('No file uploaded', 400);
    }

    if (!shopId) {
      logger.error('❌ Missing shopId');
      throw new CustomError('Shop ID is required', 400);
    }

    const owner = req.body.owner || null;

    logger.info('📤 Calling uploadGalleryImageService', {
      shopId: Number(shopId),
      owner,
    });

    const galleryImage = await uploadGalleryImageService(
      Number(shopId),
      file,
      owner
    );

    logger.info('✅ Gallery image uploaded successfully', {
      galleryId: galleryImage.galleryId,
      imageUrl: galleryImage.imageUrl,
    });

    res.status(201).json({
      success: true,
      message: 'Gallery image uploaded successfully',
      data: galleryImage,
    });
  } catch (error) {
    logger.error('❌ Error in uploadGalleryImage controller', {
      error: error.message,
      stack: error.stack,
      body: req.body,
      hasFile: !!req.file,
    });
    throw error;
  }
});

// Get gallery images
const getGalleryImages = asyncHandler(async (req, res) => {
  try {
    const { shopId } = req.params;
    const pageNumber = parseInt(req.query.pageNumber) || 1;
    const pageSize = parseInt(req.query.pageSize) || 50;

    if (!shopId) {
      throw new CustomError('Shop ID is required', 400);
    }

    const result = await getGalleryImagesService(
      Number(shopId),
      pageNumber,
      pageSize
    );

    res.status(200).json({
      success: true,
      data: result.images,
      pagination: {
        total: result.total,
        pageNumber: result.pageNumber,
        pageSize: result.pageSize,
        totalPages: result.totalPages,
      },
    });
  } catch (error) {
    logger.error('Error in getGalleryImages controller', error);
    throw error;
  }
});

// Delete gallery image
const deleteGalleryImage = asyncHandler(async (req, res) => {
  try {
    const { shopId, galleryId } = req.params;

    if (!shopId || !galleryId) {
      throw new CustomError('Shop ID and Gallery ID are required', 400);
    }

    const result = await deleteGalleryImageService(Number(shopId), Number(galleryId));

    res.status(200).json(result);
  } catch (error) {
    logger.error('Error in deleteGalleryImage controller', error);
    throw error;
  }
});

module.exports = {
  uploadGalleryImage,
  getGalleryImages,
  deleteGalleryImage,
};

