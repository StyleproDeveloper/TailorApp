const { S3Client, CreateBucketCommand, PutObjectCommand, DeleteObjectCommand, HeadBucketCommand, PutBucketCorsCommand, PutBucketPolicyCommand, PutPublicAccessBlockCommand, GetPublicAccessBlockCommand } = require('@aws-sdk/client-s3');
const fs = require('fs');
const logger = require('./logger');

// Lazy initialization of S3 client to ensure env vars are loaded
let s3Client = null;

const getS3Client = () => {
  if (!s3Client) {
    // Ensure dotenv is loaded
    if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
      // Try to load dotenv if not already loaded
      try {
        require('dotenv').config();
      } catch (e) {
        // dotenv might already be loaded
      }
    }
    
    s3Client = new S3Client({
      region: process.env.AWS_REGION || 'ap-south-1',
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
      },
    });
  }
  return s3Client;
};

/**
 * Generate a valid S3 bucket name from shop name and ID
 * S3 bucket names must be:
 * - 3-63 characters long
 * - Lowercase letters, numbers, dots, and hyphens only
 * - Must start and end with a letter or number
 */
const generateBucketName = (shopName, shopId) => {
  // Sanitize shop name: lowercase, replace spaces/special chars with hyphens
  const sanitized = (shopName || 'shop')
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
  
  // Combine with shop ID
  const bucketName = `tailorapp-${sanitized}-${shopId}`.toLowerCase();
  
  // Ensure length is within S3 limits (3-63 chars)
  if (bucketName.length > 63) {
    const maxShopNameLength = 63 - `tailorapp--${shopId}`.length;
    const truncated = sanitized.substring(0, maxShopNameLength);
    return `tailorapp-${truncated}-${shopId}`.toLowerCase();
  }
  
  if (bucketName.length < 3) {
    return `tailorapp-shop-${shopId}`.toLowerCase();
  }
  
  return bucketName;
};

/**
 * Check if a bucket exists
 */
const bucketExists = async (bucketName) => {
  try {
    const client = getS3Client();
    await client.send(new HeadBucketCommand({ Bucket: bucketName }));
    return true;
  } catch (error) {
    if (error.name === 'NotFound' || error.$metadata?.httpStatusCode === 404) {
      return false;
    }
    throw error;
  }
};

/**
 * Create an S3 bucket for a shop
 */
const createShopBucket = async (shopName, shopId) => {
  try {
    const bucketName = generateBucketName(shopName, shopId);
    
    // Check if bucket already exists
    const exists = await bucketExists(bucketName);
    if (exists) {
      logger.info('S3 bucket already exists', { bucketName, shopId });
      return bucketName;
    }
    
    // Create bucket
    const client = getS3Client();
    const createCommand = new CreateBucketCommand({
      Bucket: bucketName,
      // For regions other than us-east-1, specify LocationConstraint
      ...(process.env.AWS_REGION && process.env.AWS_REGION !== 'us-east-1' && {
        CreateBucketConfiguration: {
          LocationConstraint: process.env.AWS_REGION || 'ap-south-1',
        },
      }),
    });
    
    await client.send(createCommand);
    
    // Configure public access block settings to allow public access
    try {
      await configurePublicAccessBlock(bucketName);
      logger.info('Public access block configured for S3 bucket', { bucketName });
    } catch (publicAccessError) {
      logger.warn('Failed to configure public access block (non-critical)', { bucketName, error: publicAccessError.message });
    }
    
    // Configure bucket policy to allow public read access
    try {
      await configureBucketPublicReadPolicy(bucketName);
      logger.info('Public read policy configured for S3 bucket', { bucketName });
    } catch (policyError) {
      logger.warn('Failed to configure bucket policy (non-critical)', { bucketName, error: policyError.message });
    }
    
    // Configure CORS to allow audio playback from web browsers
    try {
      await configureBucketCors(bucketName);
      logger.info('CORS configured for S3 bucket', { bucketName });
    } catch (corsError) {
      logger.warn('Failed to configure CORS for bucket (non-critical)', { bucketName, error: corsError.message });
      // Don't fail bucket creation if CORS configuration fails
    }
    
    logger.info('S3 bucket created successfully', { bucketName, shopId, shopName });
    
    return bucketName;
  } catch (error) {
    const errorDetails = {
      name: error.name,
      message: error.message,
      code: error.Code || error.code,
      httpStatusCode: error.$metadata?.httpStatusCode,
      requestId: error.$metadata?.requestId,
      bucketName,
      shopId,
      shopName,
    };
    
    logger.error('Error creating S3 bucket', errorDetails);
    
    // Provide more detailed error message
    let errorMessage = `Failed to create S3 bucket: ${error.message || error.name}`;
    if (error.Code === 'BucketAlreadyExists' || error.name === 'BucketAlreadyOwnedByYou') {
      errorMessage = `Bucket ${bucketName} already exists`;
      // Return the existing bucket name instead of throwing
      return bucketName;
    }
    
    throw new Error(errorMessage);
  }
};

/**
 * Upload a file to S3
 * @param {string} bucketName - Name of the S3 bucket
 * @param {string} key - S3 key (path)
 * @param {Buffer|string} fileBody - File content (Buffer) or file path (string)
 * @param {string} contentType - MIME type of the file
 * @param {Object} metadata - Optional metadata
 */
const uploadToS3 = async (bucketName, key, fileBody, contentType, metadata = {}) => {
  try {
    const client = getS3Client();
    
    let body = fileBody;
    // If fileBody is a string (path), create a read stream
    if (typeof fileBody === 'string') {
      body = fs.createReadStream(fileBody);
    }

    const putCommand = new PutObjectCommand({
      Bucket: bucketName,
      Key: key,
      Body: body,
      ContentType: contentType,
      Metadata: metadata,
      // Note: ACL removed - bucket policy handles public access
      // Some buckets have ACLs disabled for security
    });
    
    await client.send(putCommand);
    
    // Generate S3 URL
    const region = process.env.AWS_REGION || 'ap-south-1';
    const s3Url = `https://${bucketName}.s3.${region}.amazonaws.com/${key}`;
    
    logger.info('File uploaded to S3 successfully', { bucketName, key, s3Url });
    
    return s3Url;
  } catch (error) {
    logger.error('Error uploading file to S3', error, { bucketName, key });
    throw new Error(`Failed to upload file to S3: ${error.message}`);
  }
};

/**
 * Delete a file from S3
 */
const deleteFromS3 = async (bucketName, key) => {
  try {
    const client = getS3Client();
    const deleteCommand = new DeleteObjectCommand({
      Bucket: bucketName,
      Key: key,
    });
    
    await client.send(deleteCommand);
    
    logger.info('File deleted from S3 successfully', { bucketName, key });
    
    return true;
  } catch (error) {
    logger.error('Error deleting file from S3', error, { bucketName, key });
    throw new Error(`Failed to delete file from S3: ${error.message}`);
  }
};

/**
 * Configure public access block settings to allow public access
 */
const configurePublicAccessBlock = async (bucketName) => {
  try {
    const client = getS3Client();
    const publicAccessBlockCommand = new PutPublicAccessBlockCommand({
      Bucket: bucketName,
      PublicAccessBlockConfiguration: {
        BlockPublicAcls: false,
        IgnorePublicAcls: false,
        BlockPublicPolicy: false,
        RestrictPublicBuckets: false,
      },
    });
    
    await client.send(publicAccessBlockCommand);
    logger.info('Public access block configured for bucket', { bucketName });
    return true;
  } catch (error) {
    logger.error('Error configuring public access block', error, { bucketName });
    throw error;
  }
};

/**
 * Configure bucket policy to allow public read access
 */
const configureBucketPublicReadPolicy = async (bucketName) => {
  try {
    const client = getS3Client();
    const region = process.env.AWS_REGION || 'ap-south-1';
    const accountId = process.env.AWS_ACCOUNT_ID || '';
    
    // Bucket policy to allow public read access
    const bucketPolicy = {
      Version: '2012-10-17',
      Statement: [
        {
          Sid: 'PublicReadGetObject',
          Effect: 'Allow',
          Principal: '*',
          Action: 's3:GetObject',
          Resource: `arn:aws:s3:::${bucketName}/*`,
        },
      ],
    };
    
    const policyCommand = new PutBucketPolicyCommand({
      Bucket: bucketName,
      Policy: JSON.stringify(bucketPolicy),
    });
    
    await client.send(policyCommand);
    logger.info('Public read policy configured for bucket', { bucketName });
    return true;
  } catch (error) {
    logger.error('Error configuring bucket policy', error, { bucketName });
    throw error;
  }
};

/**
 * Configure CORS for an S3 bucket to allow audio playback from web browsers
 */
const configureBucketCors = async (bucketName) => {
  try {
    const client = getS3Client();
    const corsCommand = new PutBucketCorsCommand({
      Bucket: bucketName,
      CORSConfiguration: {
        CORSRules: [
          {
            AllowedOrigins: ['*'], // Allow all origins - you can restrict this to specific domains
            AllowedMethods: ['GET', 'HEAD'],
            AllowedHeaders: ['*'],
            ExposeHeaders: ['ETag', 'Content-Length', 'Content-Type'],
            MaxAgeSeconds: 3000,
          },
        ],
      },
    });
    
    await client.send(corsCommand);
    logger.info('CORS configuration applied to bucket', { bucketName });
    return true;
  } catch (error) {
    logger.error('Error configuring CORS for bucket', error, { bucketName });
    throw error;
  }
};

/**
 * Extract bucket name and key from S3 URL
 */
const parseS3Url = (s3Url) => {
  try {
    // Format: https://bucket-name.s3.region.amazonaws.com/key
    const urlPattern = /https?:\/\/([^\.]+)\.s3[^\/]*\.amazonaws\.com\/(.+)/;
    const match = s3Url.match(urlPattern);
    
    if (match) {
      return {
        bucketName: match[1],
        key: match[2],
      };
    }
    
    return null;
  } catch (error) {
    logger.error('Error parsing S3 URL', error, { s3Url });
    return null;
  }
};

module.exports = {
  createShopBucket,
  uploadToS3,
  deleteFromS3,
  parseS3Url,
  generateBucketName,
  bucketExists,
  configureBucketCors,
  configureBucketPublicReadPolicy,
  configurePublicAccessBlock,
};

