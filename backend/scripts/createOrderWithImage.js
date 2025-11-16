/**
 * Script to create an order for shop 87 and upload an image to S3
 * Usage: node scripts/createOrderWithImage.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const fs = require('fs').promises;
const path = require('path');
const ShopInfo = require('../src/models/ShopModel');
const { createOrderService } = require('../src/service/OrderService');
const { uploadOrderMediaService } = require('../src/service/OrderMediaService');
const { getNextSequenceValue } = require('../src/service/sequenceService');
const envConfig = require('../src/config/env.config');

const shopId = 87;

(async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(envConfig.MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB');

    // Check shop exists and has S3 bucket
    const shop = await ShopInfo.findOne({ shop_id: shopId });
    if (!shop) {
      console.error(`❌ Shop with ID ${shopId} not found`);
      process.exit(1);
    }

    console.log(`📦 Shop: ${shop.shopName} (ID: ${shop.shop_id})`);
    console.log(`🪣 S3 Bucket: ${shop.s3BucketName || 'NOT SET'}`);

    if (!shop.s3BucketName) {
      console.error('❌ Shop does not have S3 bucket configured');
      process.exit(1);
    }

    // Get or create a customer
    const Customer = require('../src/models/CustomerModel');
    const getCustomerModel = (shop_id) => {
      const collectionName = `customer_${shop_id}`;
      return (
        mongoose.models[collectionName] ||
        mongoose.model(collectionName, Customer.schema, collectionName)
      );
    };
    const CustomerModel = getCustomerModel(shopId);

    let customer = await CustomerModel.findOne({}).limit(1);
    if (!customer) {
      // Create a test customer
      const customerId = await getNextSequenceValue('customerId', shopId);
      customer = new CustomerModel({
        customerId,
        shopId: shopId,
        branchId: 1,
        name: 'Test Customer',
        mobile: '9999999999',
        gender: 'male',
        owner: '1',
      });
      await customer.save();
      console.log(`✅ Created test customer: ${customer.name} (ID: ${customer.customerId})`);
    } else {
      console.log(`✅ Using existing customer: ${customer.name} (ID: ${customer.customerId})`);
    }

    // Get or use a dress type
    const DressType = require('../src/models/DressTypeModel');
    const getDressTypeModel = (shop_id) => {
      const collectionName = `dressType_${shop_id}`;
      return (
        mongoose.models[collectionName] ||
        mongoose.model(collectionName, DressType.schema, collectionName)
      );
    };
    const DressTypeModel = getDressTypeModel(shopId);
    
    let dressType = await DressTypeModel.findOne({}).limit(1);
    if (!dressType) {
      console.error('❌ No dress types found. Please create a dress type first.');
      process.exit(1);
    }
    console.log(`✅ Using dress type: ${dressType.name} (ID: ${dressType.dressTypeId})`);

    // Create order
    const orderData = {
      Order: {
        shop_id: shopId,
        branchId: 1,
        customerId: customer.customerId,
        stitchingType: 1, // Stitching
        noOfMeasurementDresses: 1,
        quantity: 1,
        urgent: false,
        status: 'received',
        estimationCost: 1000,
        advancereceived: 500,
        advanceReceivedDate: new Date().toISOString().split('T')[0],
        gst: false,
        gst_amount: 0,
        Courier: false,
        courierCharge: 0,
        discount: 0,
        owner: '1',
      },
      Item: [
        {
          dressTypeId: dressType.dressTypeId,
          Measurement: {
            length: 50,
            shoulder_width: 40,
            bust: 36,
          },
          Pattern: [
            {
              category: 'Neck',
              name: ['Round Neck'],
            },
          ],
          special_instructions: 'Test order for S3 image upload',
          recording: '',
          videoLink: '',
          pictures: [],
          delivery_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 days from now
          amount: 1000,
          status: 'received',
          owner: '1',
        },
      ],
      AdditionalCosts: [],
    };

    console.log('\n📝 Creating order...');
    const createdOrder = await createOrderService(orderData, shopId);
    const orderId = createdOrder.orderId;
    console.log(`✅ Order created: ID ${orderId}`);

    // Get the order item ID
    const OrderItem = require('../src/models/OrderItemModel');
    const getOrderItemModel = (shop_id) => {
      const collectionName = `orderItem_${shop_id}`;
      return (
        mongoose.models[collectionName] ||
        mongoose.model(collectionName, OrderItem.schema, collectionName)
      );
    };
    const OrderItemModel = getOrderItemModel(shopId);
    const orderItem = await OrderItemModel.findOne({ orderId }).limit(1);
    
    if (!orderItem) {
      console.error('❌ Order item not found');
      process.exit(1);
    }

    console.log(`✅ Order item found: ID ${orderItem.orderItemId}`);

    // Create a test image file
    console.log('\n🖼️  Creating test image...');
    const testImagePath = path.join(__dirname, 'test-image.png');
    
    // Create a simple 1x1 PNG image (minimal valid PNG)
    const pngBuffer = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      'base64'
    );
    
    await fs.writeFile(testImagePath, pngBuffer);
    console.log(`✅ Test image created: ${testImagePath}`);

    // Upload image to S3
    console.log('\n📤 Uploading image to S3...');
    const file = {
      buffer: pngBuffer,
      originalname: 'test-order-image.png',
      mimetype: 'image/png',
      size: pngBuffer.length,
    };

    const uploadedMedia = await uploadOrderMediaService(
      shopId,
      orderId,
      orderItem.orderItemId,
      file,
      'image',
      '1'
    );

    console.log(`✅ Image uploaded successfully!`);
    console.log(`   Media ID: ${uploadedMedia.orderMediaId}`);
    console.log(`   Media URL: ${uploadedMedia.mediaUrl}`);
    console.log(`   File Name: ${uploadedMedia.fileName}`);
    console.log(`   File Size: ${uploadedMedia.fileSize} bytes`);

    // Verify it's an S3 URL
    if (uploadedMedia.mediaUrl.startsWith('https://') && uploadedMedia.mediaUrl.includes('.s3.')) {
      console.log(`\n✅ SUCCESS: Image is stored in S3!`);
      console.log(`   S3 URL: ${uploadedMedia.mediaUrl}`);
    } else {
      console.log(`\n⚠️  WARNING: Image might not be in S3`);
      console.log(`   URL: ${uploadedMedia.mediaUrl}`);
    }

    // Clean up test image
    await fs.unlink(testImagePath);
    console.log(`\n🧹 Cleaned up test image file`);

    console.log(`\n✅ Test completed successfully!`);
    console.log(`   Order ID: ${orderId}`);
    console.log(`   Order Item ID: ${orderItem.orderItemId}`);
    console.log(`   Media ID: ${uploadedMedia.orderMediaId}`);
    console.log(`   S3 URL: ${uploadedMedia.mediaUrl}`);

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

