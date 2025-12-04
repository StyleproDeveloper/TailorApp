const express = require('express');
const multer = require('multer');
const path = require('path');
const os = require('os');
const {
  uploadGalleryImage,
  getGalleryImages,
  deleteGalleryImage,
} = require('../controller/GalleryController');

const router = express.Router();

// Configure multer for disk storage (temporary storage in system temp dir)
// This prevents OOM errors with large files by writing them to disk instead of RAM
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, os.tmpdir());
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB limit (increased for large images)
  },
  fileFilter: (req, file, cb) => {
    // Allow only image files - comprehensive list including HEIC
    const allowedMimes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/heic',
      'image/heif',
      'image/bmp',
      'image/tiff',
      'image/tif',
      'image/x-icon',
      'image/svg+xml',
    ];

    // Log for debugging
    console.log('📤 Gallery file upload - mimetype:', file.mimetype, 'originalname:', file.originalname);
    
    // If mimetype is missing or generic, try to infer from filename
    let mimetype = file.mimetype;
    if ((!mimetype || mimetype === 'application/octet-stream') && file.originalname) {
      const ext = file.originalname.toLowerCase().split('.').pop();
      const mimeMap = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'heic': 'image/heic',
        'heif': 'image/heic',
        'bmp': 'image/bmp',
        'tiff': 'image/tiff',
        'tif': 'image/tiff',
        'ico': 'image/x-icon',
        'svg': 'image/svg+xml',
      };
      mimetype = mimeMap[ext] || mimetype; // Use inferred type or keep original if not found
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
      cb(new Error(`Invalid file type: ${mimetype}. Only image files are allowed.`), false);
    }
  },
});

/**
 * @swagger
 * /gallery/{shopId}/upload:
 *   post:
 *     summary: Upload a gallery image
 *     tags: [Gallery]
 *     consumes:
 *       - multipart/form-data
 *     parameters:
 *       - in: path
 *         name: shopId
 *         required: true
 *         schema:
 *           type: number
 *       - in: formData
 *         name: file
 *         type: file
 *         required: true
 *         description: Image file
 *       - in: formData
 *         name: owner
 *         type: string
 *     responses:
 *       201:
 *         description: Image uploaded successfully
 *       400:
 *         description: Bad request
 *       500:
 *         description: Server error
 */
router.post('/:shopId/upload', upload.single('file'), uploadGalleryImage);

/**
 * @swagger
 * /gallery/{shopId}:
 *   get:
 *     summary: Get all gallery images for a shop
 *     tags: [Gallery]
 *     parameters:
 *       - in: path
 *         name: shopId
 *         required: true
 *         schema:
 *           type: number
 *       - in: query
 *         name: pageNumber
 *         schema:
 *           type: number
 *           default: 1
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: number
 *           default: 50
 *     responses:
 *       200:
 *         description: List of gallery images
 *       400:
 *         description: Bad request
 *       500:
 *         description: Server error
 */
router.get('/:shopId', getGalleryImages);

/**
 * @swagger
 * /gallery/{shopId}/{galleryId}:
 *   delete:
 *     summary: Delete a gallery image
 *     tags: [Gallery]
 *     parameters:
 *       - in: path
 *         name: shopId
 *         required: true
 *         schema:
 *           type: number
 *       - in: path
 *         name: galleryId
 *         required: true
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Image deleted successfully
 *       400:
 *         description: Bad request
 *       500:
 *         description: Server error
 */
router.delete('/:shopId/:galleryId', deleteGalleryImage);

module.exports = router;

