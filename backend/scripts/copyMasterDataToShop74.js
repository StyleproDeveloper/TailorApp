const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const DressTypeMeasurementSchema = require('../src/models/DressTypeMeasurementModel').schema;
const DressTypeDresspatternSchema = require('../src/models/DressTypeDresspatternModel').schema;
const { getNextSequenceValue } = require('../src/service/sequenceService');

const shopId = 74;

const copyMasterDataToShop = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URL);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;

    // Get dynamic models for shop 74
    const DressTypeMeasurementModel = mongoose.models[`dressTypeMeasurement_${shopId}`] ||
      mongoose.model(`dressTypeMeasurement_${shopId}`, DressTypeMeasurementSchema, `dressTypeMeasurement_${shopId}`);

    const DressTypeDressPatternModel = mongoose.models[`dressTypeDressPattern_${shopId}`] ||
      mongoose.model(`dressTypeDressPattern_${shopId}`, DressTypeDresspatternSchema, `dressTypeDressPattern_${shopId}`);

    // 1. Copy dressTypeMeasurement data
    console.log(`\n📋 Copying dressTypeMeasurement data to shop ${shopId}...`);
    const masterMeasurements = await db.collection('masterdresstypemeasurements').find({}).toArray();
    console.log(`   Found ${masterMeasurements.length} documents in masterdresstypemeasurements`);

    if (masterMeasurements.length > 0) {
      // Generate unique IDs for documents that don't have dressTypeMeasurementId
      const measurementsToInsert = await Promise.all(masterMeasurements.map(async (doc, index) => {
        const { _id, ...rest } = doc;
        // Map old format to new format
        let dressTypeMeasurementId = rest.dressTypeMeasurementId ?? null;
        
        // Generate unique ID if missing (required for unique index)
        if (!dressTypeMeasurementId) {
          // Use a combination of shopId, dressTypeId, measurementId, and index to create unique ID
          const dressTypeId = rest.DressType_ID ?? rest.dressTypeId ?? 0;
          const measurementId = rest.Measurement_ID ?? rest.measurementId ?? 0;
          // Create a unique ID: shopId * 10000000 + dressTypeId * 100000 + measurementId * 1000 + index
          // This ensures uniqueness even if multiple records have same dressTypeId and measurementId
          dressTypeMeasurementId = (shopId * 10000000) + (dressTypeId * 100000) + (measurementId * 1000) + index;
        }
        
        return {
          dressTypeId: rest.DressType_ID ?? rest.dressTypeId ?? null,
          measurementId: rest.Measurement_ID ?? rest.measurementId ?? null,
          name: rest.Measurement ?? rest.name ?? '',
          dressTypeMeasurementId: dressTypeMeasurementId,
          owner: rest.owner ?? null,
        };
      }));

      // Check existing count
      const existingCount = await DressTypeMeasurementModel.countDocuments();
      console.log(`   Existing documents in dressTypeMeasurement_${shopId}: ${existingCount}`);

      if (existingCount > 0) {
        console.log(`   🗑️  Deleting ${existingCount} existing documents...`);
        await DressTypeMeasurementModel.deleteMany({});
        console.log(`   ✅ Deleted existing documents`);
      }

      await DressTypeMeasurementModel.insertMany(measurementsToInsert);
      console.log(`   ✅ Inserted ${measurementsToInsert.length} documents into dressTypeMeasurement_${shopId}`);
    } else {
      console.log('   ⚠️  No data found in masterdresstypemeasurements');
    }

    // 2. Copy dressTypeDressPattern data
    console.log(`\n📋 Copying dressTypeDressPattern data to shop ${shopId}...`);
    const masterPatterns = await db.collection('masterdresstypedresspattern').find({}).toArray();
    console.log(`   Found ${masterPatterns.length} documents in masterdresstypedresspattern`);

    if (masterPatterns.length > 0) {
      const patternsToInsert = await Promise.all(masterPatterns.map(async (doc, index) => {
        const { _id, ...rest } = doc;
        // Map old format to new format
        let dressTypePatternId = rest.dressTypePatternId ?? rest.Id ?? null;
        if (!dressTypePatternId) {
          // Generate a unique ID if missing
          dressTypePatternId = Date.now() + index;
        }

        return {
          dressTypeId: rest.DressType_ID ?? rest.dressTypeId ?? null,
          dressPatternId: rest.DressPattern_ID ?? rest.dressPatternId ?? null,
          dressTypePatternId: dressTypePatternId,
          category: rest.category ?? null,
          owner: rest.owner ?? null,
        };
      }));

      // Check existing count
      const existingCount = await DressTypeDressPatternModel.countDocuments();
      console.log(`   Existing documents in dressTypeDressPattern_${shopId}: ${existingCount}`);

      if (existingCount > 0) {
        console.log(`   🗑️  Deleting ${existingCount} existing documents...`);
        await DressTypeDressPatternModel.deleteMany({});
        console.log(`   ✅ Deleted existing documents`);
      }

      if (patternsToInsert.length > 0) {
        await DressTypeDressPatternModel.insertMany(patternsToInsert);
        console.log(`   ✅ Inserted ${patternsToInsert.length} documents into dressTypeDressPattern_${shopId}`);
      }
    } else {
      console.log('   ⚠️  No data found in masterdresstypedresspattern');
    }

    // Final counts
    const finalMeasurementCount = await DressTypeMeasurementModel.countDocuments();
    const finalPatternCount = await DressTypeDressPatternModel.countDocuments();

    console.log(`\n✅ Copy Complete!`);
    console.log(`   dressTypeMeasurement_${shopId}: ${finalMeasurementCount} documents`);
    console.log(`   dressTypeDressPattern_${shopId}: ${finalPatternCount} documents`);

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await mongoose.disconnect();
    process.exit(1);
  }
};

copyMasterDataToShop();

