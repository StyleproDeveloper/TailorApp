const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const MONGO_URL = process.env.MONGO_URL;

if (!MONGO_URL) {
  console.error('❌ MONGO_URL is not defined in .env file');
  process.exit(1);
}

// DressType schema (simplified for this script)
const DressTypeSchema = new mongoose.Schema({}, { strict: false });
const DressType1 = mongoose.model('DressType1', DressTypeSchema, 'dressType_1');
const MasterDressType = mongoose.model('MasterDressType', DressTypeSchema, 'masterdresstype');

async function copyDressTypesToMaster() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB\n');

    // Check if source collection exists and get count
    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    const sourceCollectionExists = collections.some(c => c.name === 'dressType_1');
    
    if (!sourceCollectionExists) {
      console.log('❌ Source collection "dressType_1" does not exist');
      await mongoose.connection.close();
      return;
    }

    // Get all documents from dressType_1
    console.log('📖 Reading documents from dressType_1...');
    const dressTypes = await DressType1.find({}).lean();
    console.log(`✅ Found ${dressTypes.length} dress types in dressType_1\n`);

    if (dressTypes.length === 0) {
      console.log('⚠️  No dress types found in dressType_1. Nothing to copy.');
      await mongoose.connection.close();
      return;
    }

    // Check if masterdresstype collection already exists
    const masterCollectionExists = collections.some(c => c.name === 'masterdresstype');
    
    if (masterCollectionExists) {
      const existingCount = await MasterDressType.countDocuments();
      console.log(`⚠️  Collection "masterdresstype" already exists with ${existingCount} documents`);
      console.log('🗑️  Deleting existing masterdresstype collection...');
      await db.collection('masterdresstype').drop();
      console.log('✅ Deleted existing masterdresstype collection\n');
    }

    // Insert all documents into masterdresstype
    console.log('📝 Copying documents to masterdresstype...');
    
    // Remove _id field from documents to let MongoDB generate new ones
    const documentsToInsert = dressTypes.map(doc => {
      const { _id, ...rest } = doc;
      return rest;
    });

    if (documentsToInsert.length > 0) {
      await MasterDressType.insertMany(documentsToInsert);
      console.log(`✅ Successfully copied ${documentsToInsert.length} dress types to masterdresstype\n`);
    }

    // Verify the copy
    const masterCount = await MasterDressType.countDocuments();
    console.log('📊 Verification:');
    console.log(`   - Source (dressType_1): ${dressTypes.length} documents`);
    console.log(`   - Destination (masterdresstype): ${masterCount} documents`);

    if (masterCount === dressTypes.length) {
      console.log('✅ Copy verified successfully! All records copied.');
    } else {
      console.log('⚠️  Warning: Document count mismatch!');
    }

    // Show sample of copied data
    if (masterCount > 0) {
      const sample = await MasterDressType.findOne();
      console.log('\n📋 Sample record in masterdresstype:');
      console.log(JSON.stringify(sample, null, 2));
    }

    await mongoose.connection.close();
    console.log('\n🔌 Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error during copy:', error);
    process.exit(1);
  }
}

// Run the copy
copyDressTypesToMaster();

