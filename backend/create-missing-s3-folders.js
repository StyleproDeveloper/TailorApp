const mongoose = require('mongoose');
require('dotenv').config();
const ShopInfo = require('./src/models/ShopModel');
const { bucketExists, createShopBucket, uploadToS3 } = require('./src/utils/s3Service');
const logger = require('./src/utils/logger');

const MONGO_URL = process.env.MONGO_URL || 'mongodb+srv://StylePro:stylePro123@stylepro.5ttc1.mongodb.net/';

/**
 * Get Order Model for a specific shop
 */
const getOrderModel = (shop_id) => {
  const Order = require('./src/models/OrderModel');
  const collectionName = `order_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Order.schema, collectionName)
  );
};

/**
 * Create S3 folder for a specific order
 */
async function createOrderFolder(shopId, orderId, bucketName) {
  try {
    const orderFolderKey = `order_${orderId}/.folder`;
    const placeholderContent = Buffer.from(`Order ${orderId} created on ${new Date().toISOString()}`);
    
    await uploadToS3(
      bucketName,
      orderFolderKey,
      placeholderContent,
      'text/plain',
      {
        shopId: shopId.toString(),
        orderId: orderId.toString(),
        type: 'folder-marker',
      }
    );
    
    logger.info('Order folder created in S3', {
      shopId,
      orderId,
      bucketName,
      folderKey: orderFolderKey,
    });
    
    return true;
  } catch (error) {
    logger.error('Failed to create order folder in S3', {
      shopId,
      orderId,
      bucketName,
      error: error.message,
      errorName: error.name,
    });
    return false;
  }
}

/**
 * Process a specific shop
 */
async function processShop(shopId, orderId = null) {
  try {
    console.log(`\n🔍 Processing Shop ID: ${shopId}`);
    
    // Find shop
    const shop = await ShopInfo.findOne({ shop_id: Number(shopId) });
    if (!shop) {
      console.log(`❌ Shop ${shopId} not found`);
      return;
    }
    
    console.log(`✅ Shop found: ${shop.shopName || shop.yourName}`);
    
    // Check AWS credentials
    const hasAwsCredentials = process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY;
    if (!hasAwsCredentials) {
      console.log('❌ AWS credentials not configured');
      return;
    }
    
    // Get or create bucket
    let bucketName = shop.s3BucketName;
    
    if (!bucketName) {
      console.log('📦 Creating new S3 bucket...');
      bucketName = await createShopBucket(shop.shopName || shop.yourName, shopId);
      shop.s3BucketName = bucketName;
      await shop.save();
      console.log(`✅ Bucket created: ${bucketName}`);
    } else {
      // Verify bucket exists
      const exists = await bucketExists(bucketName);
      if (!exists) {
        console.log(`⚠️  Bucket name exists but bucket not found, recreating...`);
        bucketName = await createShopBucket(shop.shopName || shop.yourName, shopId);
        shop.s3BucketName = bucketName;
        await shop.save();
        console.log(`✅ Bucket recreated: ${bucketName}`);
      } else {
        console.log(`✅ Bucket verified: ${bucketName}`);
      }
    }
    
    // Get orders
    const OrderModel = getOrderModel(shopId);
    let orders;
    
    if (orderId) {
      // Process specific order
      orders = await OrderModel.find({ orderId: Number(orderId) });
      console.log(`\n📋 Processing specific order: ${orderId}`);
    } else {
      // Process all orders
      orders = await OrderModel.find({}).select('orderId').lean();
      console.log(`\n📋 Found ${orders.length} orders for shop ${shopId}`);
    }
    
    if (orders.length === 0) {
      console.log('ℹ️  No orders found');
      return;
    }
    
    // Create folders for each order
    let successCount = 0;
    let failCount = 0;
    
    for (const order of orders) {
      const orderId = order.orderId;
      console.log(`\n  📁 Creating folder for Order ${orderId}...`);
      
      const success = await createOrderFolder(shopId, orderId, bucketName);
      if (success) {
        successCount++;
        console.log(`  ✅ Order ${orderId} folder created`);
      } else {
        failCount++;
        console.log(`  ❌ Order ${orderId} folder creation failed`);
      }
    }
    
    console.log(`\n📊 Summary for Shop ${shopId}:`);
    console.log(`   ✅ Success: ${successCount}`);
    console.log(`   ❌ Failed: ${failCount}`);
    
  } catch (error) {
    console.error(`❌ Error processing shop ${shopId}:`, error.message);
    logger.error('Error processing shop', {
      shopId,
      error: error.message,
      stack: error.stack,
    });
  }
}

/**
 * Main function
 */
async function main() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB\n');
    
    // Get command line arguments
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
      console.log('Usage: node create-missing-s3-folders.js <shopId> [orderId]');
      console.log('Examples:');
      console.log('  node create-missing-s3-folders.js 102          # Create folders for all orders in shop 102');
      console.log('  node create-missing-s3-folders.js 102 ORD001  # Create folder for specific order');
      process.exit(1);
    }
    
    const shopId = parseInt(args[0]);
    const orderId = args[1] || null;
    
    if (isNaN(shopId)) {
      console.error('❌ Invalid shop ID');
      process.exit(1);
    }
    
    await processShop(shopId, orderId);
    
    await mongoose.connection.close();
    console.log('\n✅ Done!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Fatal error:', error);
    await mongoose.connection.close();
    process.exit(1);
  }
}

// Run the script
main();

