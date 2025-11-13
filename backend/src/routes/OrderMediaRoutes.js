const express = require('express');
const multer = require('multer');
const {
  uploadOrderMedia,
  getOrderItemMedia,
  getOrderMedia,
  deleteOrderMedia,
} = require('../controller/OrderMediaController');

const router = express.Router();

// Configure multer for memory storage (we'll save files manually)
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow images and audio files
    const allowedMimes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'audio/mpeg',
      'audio/mp3',
      'audio/wav',
      'audio/ogg',
      'audio/aac',
      'audio/m4a',
    ];

    // Log for debugging
    console.log('📤 File upload - mimetype:', file.mimetype, 'originalname:', file.originalname);
    
    // If mimetype is missing, try to infer from filename
    let mimetype = file.mimetype;
    if (!mimetype && file.originalname) {
      const ext = file.originalname.toLowerCase().split('.').pop();
      const mimeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'ogg': 'audio/ogg',
        'aac': 'audio/aac',
        'm4a': 'audio/m4a',
      };
      mimetype = mimeMap[ext] || 'image/jpeg'; // Default to jpeg if unknown
      console.log('📤 Inferred mimetype from extension:', mimetype);
    }

    if (allowedMimes.includes(mimetype)) {
      // Update file.mimetype if it was missing
      if (!file.mimetype) {
        file.mimetype = mimetype;
      }
      cb(null, true);
    } else {
      console.error('❌ Invalid file type:', mimetype, 'for file:', file.originalname);
      cb(new Error(`Invalid file type: ${mimetype}. Only images and audio files are allowed.`), false);
    }
  },
});

/**
 * @swagger
 * /order-media/upload:
 *   post:
 *     summary: Upload media for an order item
 *     tags: [Order Media]
 *     consumes:
 *       - multipart/form-data
 *     parameters:
 *       - in: formData
 *         name: file
 *         type: file
 *         required: true
 *         description: Media file (image or audio)
 *       - in: formData
 *         name: shopId
 *         type: number
 *         required: true
 *       - in: formData
 *         name: orderId
 *         type: number
 *         required: true
 *       - in: formData
 *         name: orderItemId
 *         type: number
 *         required: true
 *       - in: formData
 *         name: mediaType
 *         type: string
 *         enum: [image, audio]
 *         required: true
 *       - in: formData
 *         name: owner
 *         type: string
 *     responses:
 *       201:
 *         description: Media uploaded successfully
 *       400:
 *         description: Bad request
 *       500:
 *         description: Server error
 */
router.post('/upload', upload.single('file'), uploadOrderMedia);

/**
 * @swagger
 * /order-media/{shopId}/{orderId}/{orderItemId}:
 *   get:
 *     summary: Get all media for an order item
 *     tags: [Order Media]
 *     parameters:
 *       - in: path
 *         name: shopId
 *         required: true
 *         schema:
 *           type: number
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: number
 *       - in: path
 *         name: orderItemId
 *         required: true
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: List of media files
 *       400:
 *         description: Bad request
 *       500:
 *         description: Server error
 */
router.get('/:shopId/:orderId/:orderItemId', getOrderItemMedia);

/**
 * @swagger
 * /order-media/{shopId}/{orderId}:
 *   get:
 *     summary: Get all media for an order
 *     tags: [Order Media]
 *     parameters:
 *       - in: path
 *         name: shopId
 *         required: true
 *         schema:
 *           type: number
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: List of media files
 *       400:
 *         description: Bad request
 *       500:
 *         description: Server error
 */
router.get('/:shopId/:orderId', getOrderMedia);

/**
 * @swagger
 * /order-media/{shopId}/{orderMediaId}:
 *   delete:
 *     summary: Delete media
 *     tags: [Order Media]
 *     parameters:
 *       - in: path
 *         name: shopId
 *         required: true
 *         schema:
 *           type: number
 *       - in: path
 *         name: orderMediaId
 *         required: true
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Media deleted successfully
 *       400:
 *         description: Bad request
 *       500:
 *         description: Server error
 */
router.delete('/:shopId/:orderMediaId', deleteOrderMedia);

module.exports = router;

