# AWS S3 Integration for Image Storage

## Overview
This document describes the AWS S3 integration implemented for storing shop images. When a new shop is registered, an S3 bucket is automatically created, and all order images are uploaded to S3 instead of local storage.

## Features Implemented

### 1. S3 Bucket Creation on Shop Registration
- When a new shop is created/registered, an S3 bucket is automatically created
- Bucket name format: `tailorapp-{shopName}-{shopId}` (sanitized and lowercase)
- Bucket name is stored in the `ShopInfo` model's `s3BucketName` field

### 2. Image Upload to S3
- All order images uploaded via the OrderMedia API are stored in S3
- Images are organized in S3 with the path: `order_{orderId}/{fileName}`
- S3 URLs are stored in the database `OrderMedia` collection's `mediaUrl` field
- Falls back to local storage if S3 is not configured or upload fails

### 3. Image Deletion from S3
- When order media is deleted, the file is also removed from S3
- Supports both S3 URLs and local file paths

## Configuration

### Environment Variables
Add the following environment variables to your `.env` file:

```env
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=ap-south-1
```

### AWS IAM Permissions Required
The AWS credentials need the following S3 permissions:
- `s3:CreateBucket`
- `s3:PutObject`
- `s3:GetObject`
- `s3:DeleteObject`
- `s3:ListBucket`
- `s3:HeadBucket`

## Database Schema Changes

### ShopModel
Added new field:
- `s3BucketName` (String, optional): Stores the S3 bucket name for the shop

### OrderMediaModel
- `mediaUrl` (String): Now stores S3 URLs instead of local file paths
- Format: `https://{bucketName}.s3.{region}.amazonaws.com/{key}`

## API Behavior

### Shop Registration
- POST `/shops`
- Automatically creates S3 bucket after shop is saved
- Bucket name is stored in shop record
- Shop creation continues even if S3 bucket creation fails (logged as error)

### Order Media Upload
- POST `/order-media/upload`
- Uploads file to S3 if:
  - Shop has `s3BucketName` set
  - AWS credentials are configured
- Falls back to local storage if S3 is unavailable
- Returns S3 URL in `mediaUrl` field

### Order Media Deletion
- DELETE `/order-media/:shopId/:orderMediaId`
- Automatically detects if URL is S3 or local
- Deletes from appropriate storage location

## File Structure

```
backend/src/
├── utils/
│   └── s3Service.js          # S3 utility functions
├── service/
│   ├── ShopService.js        # Updated to create S3 buckets
│   └── OrderMediaService.js  # Updated to upload to S3
└── models/
    └── ShopModel.js          # Added s3BucketName field
```

## Migration Notes

### Existing Shops
- Existing shops without S3 buckets will continue using local storage
- To migrate existing shops:
  1. Ensure AWS credentials are configured
  2. Manually create S3 buckets or update shop records with bucket names
  3. Existing images remain in local storage until migrated

### Existing Images
- Images already stored locally will continue to work
- New uploads will use S3 if configured
- Consider migrating existing images to S3 for consistency

## Testing

### Test S3 Integration
1. Set up AWS credentials in `.env`
2. Register a new shop
3. Verify S3 bucket is created in AWS Console
4. Upload an order image
5. Verify image URL is S3 URL format
6. Delete the image and verify it's removed from S3

### Test Fallback
1. Remove AWS credentials or set invalid values
2. Register a new shop (should succeed without S3)
3. Upload an image (should use local storage)
4. Verify local file is created

## Troubleshooting

### S3 Bucket Creation Fails
- Check AWS credentials are correct
- Verify IAM permissions include `s3:CreateBucket`
- Check bucket name doesn't conflict with existing buckets
- Shop creation will still succeed, but images will use local storage

### Image Upload Fails
- Check shop has `s3BucketName` set
- Verify AWS credentials are valid
- Check IAM permissions for S3 operations
- System will automatically fallback to local storage

### Image URLs Not Working
- Verify S3 bucket has public read access (if needed)
- Check bucket CORS configuration for web access
- Ensure S3 URLs are correctly formatted

## Dependencies

Added to `package.json`:
- `@aws-sdk/client-s3`: ^3.700.0

## Next Steps

1. Install dependencies: `npm install`
2. Configure AWS credentials in environment variables
3. Test shop registration and image upload
4. Optionally migrate existing shops to use S3

