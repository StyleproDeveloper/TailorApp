const mongoose = require('mongoose');
require('dotenv').config({ path: '../.env' }); // Load .env from parent directory

const MONGO_URL = process.env.MONGO_URL;

if (!MONGO_URL) {
  console.error('❌ MONGO_URL is not defined in .env file');
  process.exit(1);
}

// Define a simplified schema for DressTypeMeasurement to interact with collections
const DressTypeMeasurementSchema = new mongoose.Schema(
  {},
  { strict: false, timestamps: true } // Allow all fields and timestamps
);

async function copyDressTypeMeasurements() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB\n');

    const SourceModel = mongoose.model('MasterDressTypeMeasurement', DressTypeMeasurementSchema, 'masterdresstypemeasurements');
    const TargetModel = mongoose.model('DressTypeMeasurement_1', DressTypeMeasurementSchema, 'dressTypeMeasurement_1');

    // Check if source collection exists and has data
    console.log('📖 Reading documents from masterdresstypemeasurements...');
    const documentsToCopy = await SourceModel.find({}).lean();
    console.log(`✅ Found ${documentsToCopy.length} dress type measurements in masterdresstypemeasurements`);

    if (documentsToCopy.length === 0) {
      console.log('⚠️ No documents found in masterdresstypemeasurements to copy.');
      await mongoose.connection.close();
      return;
    }

    // Check if target collection exists and has data
    const existingCount = await TargetModel.countDocuments();
    if (existingCount > 0) {
      console.log(`\n⚠️ Target collection dressTypeMeasurement_1 already has ${existingCount} documents.`);
      console.log('   Clearing existing data before copying...');
      
      // Clear existing data
      await TargetModel.deleteMany({});
      console.log(`   ✅ Cleared ${existingCount} existing documents`);
    }

    // Get the max dressTypeMeasurementId from target collection to generate new IDs
    const db = mongoose.connection.db;
    const targetCollection = db.collection('dressTypeMeasurement_1');
    const maxIdResult = await targetCollection
      .findOne({}, { sort: { dressTypeMeasurementId: -1 } });
    let nextId = maxIdResult && maxIdResult.dressTypeMeasurementId 
      ? maxIdResult.dressTypeMeasurementId + 1 
      : 1;

    // Remove _id and __v fields and generate IDs for documents missing them
    const documentsToInsert = documentsToCopy.map((doc, index) => {
      const { _id, __v, ...rest } = doc;
      // If dressTypeMeasurementId is null or missing, generate a new one
      if (!rest.dressTypeMeasurementId) {
        rest.dressTypeMeasurementId = nextId++;
      }
      return rest;
    });

    console.log('\n📝 Copying documents to dressTypeMeasurement_1...');
    if (documentsToInsert.length > 0) {
      // Use bulk write with upsert to replace existing documents
      const db = mongoose.connection.db;
      const targetCollection = db.collection('dressTypeMeasurement_1');
      
      let successCount = 0;
      let errorCount = 0;
      
      // Process in batches to avoid memory issues
      const batchSize = 100;
      for (let i = 0; i < documentsToInsert.length; i += batchSize) {
        const batch = documentsToInsert.slice(i, i + batchSize);
        const bulkOps = batch.map(doc => ({
          updateOne: {
            filter: {
              DressType_ID: doc.DressType_ID,
              Measurement_ID: doc.Measurement_ID
            },
            update: { $set: doc },
            upsert: true
          }
        }));
        
        try {
          const result = await targetCollection.bulkWrite(bulkOps, { ordered: false });
          successCount += result.upsertedCount + result.modifiedCount;
          if (result.writeErrors && result.writeErrors.length > 0) {
            errorCount += result.writeErrors.length;
          }
          console.log(`   Processed batch ${Math.floor(i / batchSize) + 1}: ${batch.length} documents`);
        } catch (error) {
          console.log(`   ⚠️ Error in batch ${Math.floor(i / batchSize) + 1}: ${error.message}`);
          errorCount += batch.length;
        }
      }
      
      console.log(`✅ Successfully copied/updated ${successCount} dress type measurements to dressTypeMeasurement_1`);
      if (errorCount > 0) {
        console.log(`⚠️ ${errorCount} documents had errors during processing`);
      }
    } else {
      console.log('⚠️ No documents to insert after processing.');
    }

    // Verification
    const sourceCount = await SourceModel.countDocuments();
    const targetCount = await TargetModel.countDocuments();
    console.log(`\n📊 Verification:`);
    console.log(`   - Source (masterdresstypemeasurements): ${sourceCount} documents`);
    console.log(`   - Destination (dressTypeMeasurement_1): ${targetCount} documents`);
    
    if (targetCount === sourceCount && sourceCount > 0) {
      console.log('✅ Copy verified successfully! All records copied.');
      const sampleRecord = await TargetModel.findOne({}).lean();
      console.log('\n📋 Sample record in dressTypeMeasurement_1:');
      console.log(JSON.stringify(sampleRecord, null, 2));
    } else if (sourceCount === 0 && targetCount === 0) {
      console.log('✅ Both source and destination are empty, as expected.');
    } else {
      console.log(`⚠️ Verification: Document counts do not match (Source: ${sourceCount}, Target: ${targetCount}).`);
      console.log('   This might be expected if target had existing data that was cleared.');
    }

  } catch (error) {
    console.error('❌ Error during dress type measurement copy:', error);
    if (error.message) {
      console.error('   Error message:', error.message);
    }
    if (error.stack) {
      console.error('   Stack trace:', error.stack);
    }
  } finally {
    console.log('\n🔌 Disconnecting from MongoDB');
    await mongoose.connection.close();
  }
}

copyDressTypeMeasurements();

