const mongoose = require('mongoose');
const DressTypeDresspatternModel = require('./src/models/DressTypeDresspatternModel');
const DresspatternModel = require('./src/models/DresspatternModel');

// Replace with your MongoDB connection string
const MONGO_URL = process.env.MONGO_URL || 'mongodb+srv://StylePro:stylePro123@stylepro.5ttc1.mongodb.net/';
const SHOP_ID = 1; // Assuming shop_id is 1
const DRESS_TYPE_ID = 3; // Blouse

const getModel = (shop_id, baseName, schema) => {
  const collectionName = `${baseName}_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, schema, collectionName)
  );
};

async function debugDressPatterns() {
  console.log('🔌 Connecting to MongoDB...');
  try {
    await mongoose.connect(MONGO_URL);
    console.log('✅ Connected to MongoDB');

    const DressTypePatternModel = getModel(
      SHOP_ID,
      'dressTypeDressPattern',
      DressTypeDresspatternModel.schema
    );
    const DressPatternModel = getModel(
      SHOP_ID,
      'dresspattern',
      DresspatternModel.schema
    );

    console.log(`\n📊 Debugging Dress Type ID: ${DRESS_TYPE_ID} (Blouse)`);
    console.log('=' .repeat(50));

    // Step 1: Check dresstypedresspattern_1 table
    console.log('\n1️⃣ Checking dresstypedresspattern_1 table...');
    const dressTypeDressPatterns = await DressTypePatternModel.find({
      dressTypeId: DRESS_TYPE_ID,
    }).select('Id dressTypeId dressPatternId');
    
    console.log(`📈 Found ${dressTypeDressPatterns.length} records in dresstypedresspattern_1`);
    console.log('Records:');
    dressTypeDressPatterns.forEach((record, index) => {
      console.log(`  ${index + 1}. ID: ${record._id}, dressTypeId: ${record.dressTypeId}, dressPatternId: ${record.dressPatternId} (type: ${typeof record.dressPatternId})`);
    });

    // Step 2: Extract pattern IDs
    console.log('\n2️⃣ Extracting pattern IDs...');
    const patternIds = dressTypeDressPatterns.map((item) =>
      Number(item.dressPatternId)
    );
    console.log(`🔢 Pattern IDs (converted to numbers): ${patternIds.join(', ')}`);

    // Step 3: Check dresspattern_1 table
    console.log('\n3️⃣ Checking dresspattern_1 table...');
    const dressPatterns = await DressPatternModel.find({
      dressPatternId: { $in: patternIds },
    }).select('dressPatternId name category');
    
    console.log(`📈 Found ${dressPatterns.length} matching records in dresspattern_1`);
    console.log('Matching patterns:');
    dressPatterns.forEach((pattern, index) => {
      console.log(`  ${index + 1}. dressPatternId: ${pattern.dressPatternId}, name: ${pattern.name}`);
    });

    // Step 4: Find missing patterns
    console.log('\n4️⃣ Finding missing patterns...');
    const foundPatternIds = dressPatterns.map(p => p.dressPatternId);
    const missingPatternIds = patternIds.filter(id => !foundPatternIds.includes(id));
    
    if (missingPatternIds.length > 0) {
      console.log(`❌ Missing pattern IDs: ${missingPatternIds.join(', ')}`);
      console.log('These dressPatternIds exist in dresstypedresspattern_1 but not in dresspattern_1');
    } else {
      console.log('✅ All pattern IDs found in dresspattern_1');
    }

    // Step 5: Check for data type issues
    console.log('\n5️⃣ Checking for data type issues...');
    const allDressPatterns = await DressPatternModel.find({}).select('dressPatternId');
    const allPatternIds = allDressPatterns.map(p => p.dressPatternId);
    
    console.log(`📊 Total patterns in dresspattern_1: ${allPatternIds.length}`);
    console.log(`🔢 Sample pattern IDs: ${allPatternIds.slice(0, 10).join(', ')}`);
    
    // Check if any of our pattern IDs exist as strings
    const stringPatternIds = dressTypeDressPatterns.map(item => item.dressPatternId.toString());
    const foundAsStrings = allPatternIds.filter(id => stringPatternIds.includes(id.toString()));
    
    if (foundAsStrings.length > 0) {
      console.log(`⚠️  Found ${foundAsStrings.length} patterns that exist as strings: ${foundAsStrings.join(', ')}`);
    }

    console.log('\n🎯 Summary:');
    console.log(`- dresstypedresspattern_1 records: ${dressTypeDressPatterns.length}`);
    console.log(`- dresspattern_1 matches: ${dressPatterns.length}`);
    console.log(`- Missing matches: ${dressTypeDressPatterns.length - dressPatterns.length}`);

  } catch (error) {
    console.error('❌ Error during debugging:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

debugDressPatterns();
