const mongoose = require('mongoose');
const ShopInfo = require('./src/models/ShopModel');

// Load environment variables
require('dotenv').config({ path: './backend/.env' });

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/tailorapp';

async function checkS3Bucket(shopId) {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ MongoDB connected');

    const shop = await ShopInfo.findOne({ shop_id: Number(shopId) });

    if (!shop) {
      console.log(`❌ Shop not found with ID: ${shopId}`);
      return;
    }

    console.log(`\n📦 Shop Information:`);
    console.log(`   Shop ID: ${shop.shop_id}`);
    console.log(`   Shop Name: ${shop.shopName || 'N/A'}`);
    console.log(`   S3 Bucket Name: ${shop.s3BucketName || '❌ NOT SET'}`);
    
    if (shop.s3BucketName) {
      console.log(`\n✅ S3 Configuration:`);
      console.log(`   Bucket: ${shop.s3BucketName}`);
      console.log(`   AWS Region: ${process.env.AWS_REGION || 'ap-south-1'}`);
      console.log(`   AWS Access Key ID: ${process.env.AWS_ACCESS_KEY_ID ? '✅ Set' : '❌ Not set'}`);
      console.log(`   AWS Secret Access Key: ${process.env.AWS_SECRET_ACCESS_KEY ? '✅ Set' : '❌ Not set'}`);
      console.log(`\n📁 File Path Format in S3:`);
      console.log(`   s3://${shop.s3BucketName}/order_{orderId}/{fileName}`);
      console.log(`   Example: s3://${shop.s3BucketName}/order_65/audio_1234567890_abc123.m4a`);
    } else {
      console.log(`\n⚠️  S3 is not configured for this shop.`);
      console.log(`   Files will be stored locally at: backend/uploads/shop_${shopId}/order_{orderId}/`);
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 MongoDB disconnected');
  }
}

const shopId = process.argv[2];
if (!shopId) {
  console.log('Usage: node check-s3-bucket.js <shopId>');
  console.log('Example: node check-s3-bucket.js 1');
  process.exit(1);
}

checkS3Bucket(shopId);

