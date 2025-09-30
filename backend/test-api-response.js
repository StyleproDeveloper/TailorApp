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

async function testAPIResponse() {
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

    console.log(`\n📊 Testing API Response for Dress Type ID: ${DRESS_TYPE_ID} (Blouse)`);
    console.log('=' .repeat(60));

    // Simulate the exact backend logic
    console.log('\n1️⃣ Fetching DressType-DressPattern Relations...');
    const dressTypeDressPatterns = await DressTypePatternModel.find({
      dressTypeId: DRESS_TYPE_ID,
    }).select('Id dressTypeId dressPatternId');
    
    console.log(`📈 Found ${dressTypeDressPatterns.length} relations`);

    console.log('\n2️⃣ Converting dressPatternId to Number...');
    const patternIds = dressTypeDressPatterns.map((item) =>
      Number(item.dressPatternId)
    );
    console.log(`🔢 Pattern IDs: ${patternIds.join(', ')}`);

    console.log('\n3️⃣ Fetching DressPattern Details...');
    const dressPatterns = await DressPatternModel.find({
      dressPatternId: { $in: patternIds },
    }).select('dressPatternId name category selection');
    
    console.log(`📈 Found ${dressPatterns.length} pattern details`);

    console.log('\n4️⃣ Formatting response (exact backend logic)...');
    const response = {
      DressTypeMeasurement: [], // Not testing measurements
      DressTypeDressPattern: dressTypeDressPatterns.map((dp) => {
        const patternDetails = dressPatterns.find(
          (p) => p.dressPatternId === dp.dressPatternId
        );
        
        console.log(`  - dressPatternId: ${dp.dressPatternId}, found: ${patternDetails ? 'YES' : 'NO'}`);
        
        return {
          ...dp.toObject(),
          PatternDetails: patternDetails,
        };
      }),
    };

    console.log('\n5️⃣ Final Response Analysis:');
    console.log(`📊 Total DressTypeDressPattern records: ${response.DressTypeDressPattern.length}`);
    
    const withPatternDetails = response.DressTypeDressPattern.filter(dp => dp.PatternDetails);
    const withoutPatternDetails = response.DressTypeDressPattern.filter(dp => !dp.PatternDetails);
    
    console.log(`✅ Records with PatternDetails: ${withPatternDetails.length}`);
    console.log(`❌ Records without PatternDetails: ${withoutPatternDetails.length}`);
    
    if (withoutPatternDetails.length > 0) {
      console.log('\n❌ Records without PatternDetails:');
      withoutPatternDetails.forEach((dp, index) => {
        console.log(`  ${index + 1}. dressPatternId: ${dp.dressPatternId}`);
      });
    }

    console.log('\n6️⃣ Sample Response (first 3 records):');
    console.log(JSON.stringify(response.DressTypeDressPattern.slice(0, 3), null, 2));

  } catch (error) {
    console.error('❌ Error during testing:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

testAPIResponse();
