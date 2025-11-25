const mongoose = require('mongoose');
require('dotenv').config();

const MONGO_URL = process.env.MONGO_URL || 'mongodb+srv://StylePro:stylePro123@stylepro.5ttc1.mongodb.net/';

// Collections to NEVER drop (master collections and system collections)
const PROTECTED_COLLECTIONS = [
  'shops',
  'users',
  'roles',
  'sequences',
  'masterdresstype',
  'mastermeasurements',
  'masterdresspatterns',
  'masterdresstypemeasurements',
  'masterdresstypedresspattern',
  'billingterms',
  'expenses',
  'changehistory',
  'measurementhistory',
  'dresspatterns',
  'dresstypes',
  'dresstypemeasurements',
  'dresstypedresspatterns',
];

// Collections that should be kept even if empty (important shop collections)
const KEEP_COLLECTIONS_PATTERNS = [
  /^shop_\d+$/, // Shop info collections
  /^user_\d+$/, // User collections
  /^role_\d+$/, // Role collections
  /^sequence_\d+$/, // Sequence collections
];

async function dropEmptyCollections() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    
    console.log(`\n📊 Total collections found: ${collections.length}`);
    console.log(`⚠️  MongoDB Atlas free tier limit: 500 collections\n`);

    const emptyCollections = [];
    const collectionsToDrop = [];
    let totalCount = 0;

    console.log('🔍 Checking collections...\n');

    for (const collection of collections) {
      const collectionName = collection.name;
      totalCount++;

      // Skip protected collections
      if (PROTECTED_COLLECTIONS.includes(collectionName)) {
        console.log(`✅ KEEP (protected): ${collectionName}`);
        continue;
      }

      // Skip collections matching keep patterns
      const shouldKeep = KEEP_COLLECTIONS_PATTERNS.some(pattern => pattern.test(collectionName));
      if (shouldKeep) {
        console.log(`✅ KEEP (important): ${collectionName}`);
        continue;
      }

      // Check if collection is empty
      const count = await db.collection(collectionName).countDocuments();
      
      if (count === 0) {
        emptyCollections.push(collectionName);
        collectionsToDrop.push(collectionName);
        console.log(`❌ EMPTY (will drop): ${collectionName} (0 documents)`);
      } else {
        console.log(`✅ KEEP (has data): ${collectionName} (${count} documents)`);
      }
    }

    console.log(`\n📈 Summary:`);
    console.log(`   Total collections: ${totalCount}`);
    console.log(`   Empty collections found: ${emptyCollections.length}`);
    console.log(`   Collections to drop: ${collectionsToDrop.length}`);

    if (collectionsToDrop.length === 0) {
      console.log('\n✅ No empty collections to drop!');
      await mongoose.connection.close();
      return;
    }

    console.log(`\n🗑️  Collections to be dropped:`);
    collectionsToDrop.forEach(name => console.log(`   - ${name}`));

    // Ask for confirmation (in production, you might want to add a prompt)
    console.log(`\n⚠️  WARNING: This will permanently delete ${collectionsToDrop.length} empty collections!`);
    console.log(`   Press Ctrl+C to cancel, or wait 5 seconds to proceed...\n`);

    // Wait 5 seconds
    await new Promise(resolve => setTimeout(resolve, 5000));

    console.log('🗑️  Dropping empty collections...\n');

    let droppedCount = 0;
    let errorCount = 0;

    for (const collectionName of collectionsToDrop) {
      try {
        await db.collection(collectionName).drop();
        console.log(`✅ Dropped: ${collectionName}`);
        droppedCount++;
      } catch (error) {
        console.error(`❌ Error dropping ${collectionName}: ${error.message}`);
        errorCount++;
      }
    }

    console.log(`\n📊 Drop Summary:`);
    console.log(`   ✅ Successfully dropped: ${droppedCount}`);
    console.log(`   ❌ Errors: ${errorCount}`);
    console.log(`   📉 Collections remaining: ${totalCount - droppedCount}`);

    // Check if we're under the limit
    const remainingCollections = totalCount - droppedCount;
    if (remainingCollections < 500) {
      console.log(`\n✅ SUCCESS! You're now under the 500 collection limit (${remainingCollections} collections)`);
    } else {
      console.log(`\n⚠️  WARNING: Still above limit (${remainingCollections} collections). You may need to drop more collections or upgrade MongoDB Atlas.`);
    }

    await mongoose.connection.close();
    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    await mongoose.connection.close();
    process.exit(1);
  }
}

// Run the script
dropEmptyCollections();

