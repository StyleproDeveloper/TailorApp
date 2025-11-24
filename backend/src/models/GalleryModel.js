const mongoose = require('mongoose');

const Schema = mongoose.Schema;

const GallerySchema = Schema(
  {
    galleryId: {
      type: Number,
      required: true,
      unique: true,
    },
    shopId: {
      type: Number,
      required: true,
    },
    imageUrl: {
      type: String,
      required: true,
    },
    fileName: {
      type: String,
      required: true,
    },
    fileSize: {
      type: Number, // Size in bytes
      default: 0,
    },
    mimeType: {
      type: String,
      default: null,
    },
    owner: {
      type: String,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Add indexes for better query performance
GallerySchema.index({ shopId: 1 });
GallerySchema.index({ galleryId: 1 });
GallerySchema.index({ shopId: 1, createdAt: -1 });

module.exports = mongoose.model('Gallery', GallerySchema);

