const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const MONGO_URL = process.env.MONGO_URL;

if (!MONGO_URL) {
  console.error('❌ MONGO_URL is not defined in .env file');
  process.exit(1);
}

// Shop model schema (simplified for this script)
const ShopSchema = new mongoose.Schema({}, { strict: false, collection: 'shops' });
const Shop = mongoose.model('Shop', ShopSchema);

// List of collection prefixes that are created per shop
const SHOP_COLLECTIONS = [
  'dressType',
  'customer',
  'dresspattern',
  'dressTypeDressPattern',
  'dressTypeMeasurement',
  'measurementHistory',
  'measurement',
  'orderItem',
  'order',
  'orderitemadditionalcost',
  'role',
];

async function deleteShopCollections(shopId) {
  const db = mongoose.connection.db;
  const collectionsToDelete = SHOP_COLLECTIONS.map(prefix => `${prefix}_${shopId}`);
  
  console.log(`\n🗑️  Deleting collections for shop ${shopId}:`);
  
  for (const collectionName of collectionsToDelete) {
    try {
      const collection = db.collection(collectionName);
      const count = await collection.countDocuments();
      
      if (count > 0) {
        await collection.drop();
        console.log(`  ✅ Deleted collection: ${collectionName} (${count} documents)`);
      } else {
        // Collection might not exist or is empty, try to drop it anyway
        try {
          await collection.drop();
          console.log(`  ✅ Dropped empty collection: ${collectionName}`);
        } catch (err) {
          // Collection doesn't exist, that's fine
          console.log(`  ⚠️  Collection doesn't exist: ${collectionName}`);
        }
      }
    } catch (error) {
      console.log(`  ⚠️  Error deleting collection ${collectionName}: ${error.message}`);
    }
  }
}

async function cleanupShops() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB\n');

    // First, let's check all shops to see what exists
    const allShops = await Shop.find({});
    console.log(`📊 Total shops in database: ${allShops.length}`);
    allShops.forEach(shop => {
      console.log(`  - Shop ID: ${shop.shop_id}, Name: ${shop.shopName || shop.yourName || 'N/A'}`);
    });

    // Find all shops except shopId 1
    const shopsToDelete = await Shop.find({ shop_id: { $ne: 1 } });
    
    console.log(`\n📊 Found ${shopsToDelete.length} shops to delete (keeping shopId 1)`);
    
    // Check what collections exist
    const db = mongoose.connection.db;
    const allCollections = await db.listCollections().toArray();
    const shopCollections = allCollections.filter(c => {
      const parts = c.name.split('_');
      return parts.length === 2 && /^\d+$/.test(parts[1]);
    });
    
    console.log(`\n📋 Found ${shopCollections.length} shop-specific collections`);
    
    // Extract unique shopIds from collections
    const shopIdsFromCollections = new Set();
    shopCollections.forEach(c => {
      const shopId = parseInt(c.name.split('_')[1]);
      if (!isNaN(shopId)) {
        shopIdsFromCollections.add(shopId);
      }
    });
    
    console.log(`📊 Found collections for ${shopIdsFromCollections.size} different shopIds`);
    console.log(`   ShopIds: ${Array.from(shopIdsFromCollections).sort((a, b) => a - b).join(', ')}`);
    
    // Find shopIds to delete (all except 1)
    const shopIdsToDelete = Array.from(shopIdsFromCollections).filter(id => id !== 1);
    
    if (shopIdsToDelete.length === 0) {
      console.log('\n✅ No collections to delete. Only shopId 1 collections exist.');
      await mongoose.connection.close();
      return;
    }
    
    console.log(`\n🗑️  Will delete collections for shopIds: ${shopIdsToDelete.sort((a, b) => a - b).join(', ')}`);
    console.log(`   (Keeping shopId 1 collections)`);
    
    // Delete shops first (if any exist)
    if (shopsToDelete.length > 0) {
      console.log(`\n🗑️  Deleting ${shopsToDelete.length} shop documents...`);
      for (const shop of shopsToDelete) {
        await Shop.deleteOne({ shop_id: shop.shop_id });
        console.log(`  ✅ Deleted shop: shopId ${shop.shop_id}`);
      }
    }
    
    // Now delete collections for all shopIds except 1
    let deletedCollections = 0;
    for (const shopId of shopIdsToDelete) {
      console.log(`\n🗑️  Deleting collections for shopId ${shopId}...`);
      await deleteShopCollections(shopId);
      deletedCollections += SHOP_COLLECTIONS.length;
    }
    
    console.log(`\n✅ Cleanup complete!`);
    console.log(`   - Deleted ${shopsToDelete.length} shop documents`);
    console.log(`   - Deleted collections for ${shopIdsToDelete.length} shopIds`);
    console.log(`   - Freed up approximately ${deletedCollections} collections`);
    console.log(`   - Shop ID 1 collections are preserved`);
    
    await mongoose.connection.close();
    return;

    // Show shops that will be deleted
    console.log('\n📋 Shops to be deleted:');
    shopsToDelete.forEach(shop => {
      console.log(`  - Shop ID: ${shop.shop_id}, Name: ${shop.shopName || 'N/A'}`);
    });

    // Delete collections and shops
    let deletedCount = 0;
    for (const shop of shopsToDelete) {
      const shopId = shop.shop_id;
      console.log(`\n🗑️  Processing shop ${shopId}...`);
      
      // Delete all collections for this shop
      await deleteShopCollections(shopId);
      
      // Delete the shop document
      await Shop.deleteOne({ shop_id: shopId });
      console.log(`  ✅ Deleted shop document: shopId ${shopId}`);
      deletedCount++;
    }

    console.log(`\n✅ Cleanup complete!`);
    console.log(`   - Deleted ${deletedCount} shops`);
    console.log(`   - Deleted ${deletedCount * SHOP_COLLECTIONS.length} collections`);
    console.log(`   - Freed up approximately ${deletedCount * SHOP_COLLECTIONS.length} collections`);
    console.log(`   - Shop ID 1 is preserved`);

    // Verify shopId 1 still exists
    const shop1 = await Shop.findOne({ shop_id: 1 });
    if (shop1) {
      console.log(`\n✅ Verified: Shop ID 1 still exists (${shop1.shopName || 'N/A'})`);
    } else {
      console.log(`\n⚠️  Warning: Shop ID 1 not found!`);
    }

    await mongoose.connection.close();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    process.exit(1);
  }
}

// Run the cleanup
cleanupShops();

