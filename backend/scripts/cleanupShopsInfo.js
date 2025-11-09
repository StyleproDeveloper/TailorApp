const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const MONGO_URL = process.env.MONGO_URL;

if (!MONGO_URL) {
  console.error('❌ MONGO_URL is not defined in .env file');
  process.exit(1);
}

// ShopInfo model schema (simplified for this script)
const ShopInfoSchema = new mongoose.Schema({}, { strict: false, collection: 'shops' });
const ShopInfo = mongoose.model('ShopInfo', ShopInfoSchema);

async function cleanupShopsInfo() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB\n');

    // Find all shops except shopId 1
    const shopsToDelete = await ShopInfo.find({ shop_id: { $ne: 1 } });
    
    console.log(`📊 Total shops in database:`);
    const allShops = await ShopInfo.find({});
    console.log(`   - Total: ${allShops.length}`);
    allShops.forEach(shop => {
      console.log(`     Shop ID: ${shop.shop_id}, Name: ${shop.shopName || shop.yourName || 'N/A'}`);
    });
    
    console.log(`\n📊 Found ${shopsToDelete.length} shops to delete (keeping shopId 1)`);
    
    if (shopsToDelete.length === 0) {
      console.log('✅ No shops to delete. Only shopId 1 exists.');
      await mongoose.connection.close();
      return;
    }

    // Show shops that will be deleted
    console.log('\n📋 Shops to be deleted:');
    shopsToDelete.forEach(shop => {
      console.log(`  - Shop ID: ${shop.shop_id}, Name: ${shop.shopName || shop.yourName || 'N/A'}`);
    });

    // Delete shops
    console.log(`\n🗑️  Deleting ${shopsToDelete.length} shop records...`);
    let deletedCount = 0;
    for (const shop of shopsToDelete) {
      await ShopInfo.deleteOne({ shop_id: shop.shop_id });
      console.log(`  ✅ Deleted shop: shopId ${shop.shop_id}`);
      deletedCount++;
    }

    console.log(`\n✅ Cleanup complete!`);
    console.log(`   - Deleted ${deletedCount} shop records`);
    console.log(`   - Shop ID 1 is preserved`);

    // Verify shopId 1 still exists
    const shop1 = await ShopInfo.findOne({ shop_id: 1 });
    if (shop1) {
      console.log(`\n✅ Verified: Shop ID 1 still exists (${shop1.shopName || shop1.yourName || 'N/A'})`);
    } else {
      console.log(`\n⚠️  Warning: Shop ID 1 not found!`);
    }

    // Show final count
    const finalCount = await ShopInfo.countDocuments();
    console.log(`\n📊 Final shop count: ${finalCount}`);

    await mongoose.connection.close();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    process.exit(1);
  }
}

// Run the cleanup
cleanupShopsInfo();

