/**
 * Script to manually create S3 bucket for an existing shop
 * Usage: node scripts/createShopBucket.js <shopId> [shopName]
 */

require('dotenv').config();
const mongoose = require('mongoose');
const ShopInfo = require('../src/models/ShopModel');
const { createShopBucket } = require('../src/utils/s3Service');
const envConfig = require('../src/config/env.config');

const shopId = process.argv[2];
const shopName = process.argv[3];

if (!shopId) {
  console.error('❌ Usage: node scripts/createShopBucket.js <shopId> [shopName]');
  process.exit(1);
}

(async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(envConfig.MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB');

    // Find the shop
    const shop = await ShopInfo.findOne({ shop_id: Number(shopId) });
    
    if (!shop) {
      console.error(`❌ Shop with ID ${shopId} not found`);
      process.exit(1);
    }

    console.log(`📦 Found shop: ${shop.shopName || shop.yourName} (ID: ${shop.shop_id})`);
    
    if (shop.s3BucketName) {
      console.log(`ℹ️  Shop already has S3 bucket: ${shop.s3BucketName}`);
      const update = process.argv.includes('--force');
      if (!update) {
        console.log('   Use --force flag to recreate the bucket');
        process.exit(0);
      }
    }

    // Create S3 bucket
    const nameToUse = shopName || shop.shopName || shop.yourName;
    console.log(`🪣 Creating S3 bucket for: ${nameToUse}...`);
    
    const bucketName = await createShopBucket(nameToUse, shop.shop_id);
    
    // Update shop with bucket name
    shop.s3BucketName = bucketName;
    await shop.save();
    
    console.log(`✅ S3 bucket created and saved: ${bucketName}`);
    console.log(`✅ Shop updated successfully`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.stack) {
      console.error(error.stack);
    }
    process.exit(1);
  } finally {
    await mongoose.connection.close();
  }
})();

