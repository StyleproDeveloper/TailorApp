const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const MONGO_URL = process.env.MONGO_URL;

if (!MONGO_URL) {
  console.error('❌ MONGO_URL is not defined in .env file');
  process.exit(1);
}

// Define schemas (simplified, using strict: false to allow all fields)
const GenericSchema = new mongoose.Schema({}, { strict: false });

// Source collections (shop_1)
const Measurement1 = mongoose.model('Measurement1', GenericSchema, 'measurement_1');
const DressPattern1 = mongoose.model('DressPattern1', GenericSchema, 'dresspattern_1');
const DressTypeMeasurement1 = mongoose.model('DressTypeMeasurement1', GenericSchema, 'dresstypemeasurement_1');
const DressTypeDressPattern1 = mongoose.model('DressTypeDressPattern1', GenericSchema, 'dresstypedresspattern_1');

// Master collections
const MasterMeasurement = mongoose.model('MasterMeasurement', GenericSchema, 'mastermeasurements');
const MasterDressPattern = mongoose.model('MasterDressPattern', GenericSchema, 'masterdresspatterns');
const MasterDressTypeMeasurement = mongoose.model('MasterDressTypeMeasurement', GenericSchema, 'masterdresstypemeasurements');
const MasterDressTypeDressPattern = mongoose.model('MasterDressTypeDressPattern', GenericSchema, 'masterdresstypedresspattern');

async function copyCollection(sourceModel, destModel, sourceName, destName) {
  try {
    console.log(`\n📖 Processing ${sourceName} -> ${destName}...`);
    
    // Check if source collection exists
    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    const sourceExists = collections.some(c => c.name === sourceName);
    
    if (!sourceExists) {
      console.log(`   ⚠️  Source collection "${sourceName}" does not exist. Skipping.`);
      return { copied: 0, skipped: true };
    }

    // Get all documents from source
    const sourceDocs = await sourceModel.find({}).lean();
    console.log(`   📊 Found ${sourceDocs.length} documents in ${sourceName}`);

    if (sourceDocs.length === 0) {
      console.log(`   ⚠️  No documents found in ${sourceName}. Skipping.`);
      return { copied: 0, skipped: true };
    }

    // Check if destination collection already exists
    const destExists = collections.some(c => c.name === destName);
    
    if (destExists) {
      const existingCount = await destModel.countDocuments();
      console.log(`   ⚠️  Collection "${destName}" already exists with ${existingCount} documents`);
      console.log(`   🗑️  Deleting existing ${destName} collection...`);
      await db.collection(destName).drop();
      console.log(`   ✅ Deleted existing ${destName} collection`);
    }

    // Remove _id field from documents to let MongoDB generate new ones
    const documentsToInsert = sourceDocs.map(doc => {
      const { _id, __v, ...rest } = doc;
      return rest;
    });

    if (documentsToInsert.length > 0) {
      await destModel.insertMany(documentsToInsert);
      console.log(`   ✅ Successfully copied ${documentsToInsert.length} documents to ${destName}`);
    }

    // Verify the copy
    const destCount = await destModel.countDocuments();
    console.log(`   📊 Verification: ${sourceDocs.length} -> ${destCount} documents`);

    if (destCount === sourceDocs.length) {
      console.log(`   ✅ Copy verified successfully!`);
    } else {
      console.log(`   ⚠️  Warning: Document count mismatch!`);
    }

    return { copied: destCount, skipped: false };
  } catch (error) {
    console.error(`   ❌ Error copying ${sourceName} to ${destName}:`, error.message);
    return { copied: 0, skipped: false, error: error.message };
  }
}

async function copyAllMasterData() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URL, {
      connectTimeoutMS: 30000,
      socketTimeoutMS: 45000,
    });
    console.log('✅ Connected to MongoDB\n');

    const results = [];

    // Copy measurements
    const measurementResult = await copyCollection(
      Measurement1,
      MasterMeasurement,
      'measurement_1',
      'mastermeasurements'
    );
    results.push({ collection: 'measurements', ...measurementResult });

    // Copy dress patterns
    const patternResult = await copyCollection(
      DressPattern1,
      MasterDressPattern,
      'dresspattern_1',
      'masterdresspatterns'
    );
    results.push({ collection: 'dresspatterns', ...patternResult });

    // Copy dress type measurements
    const dressTypeMeasurementResult = await copyCollection(
      DressTypeMeasurement1,
      MasterDressTypeMeasurement,
      'dresstypemeasurement_1',
      'masterdresstypemeasurements'
    );
    results.push({ collection: 'dresstypemeasurements', ...dressTypeMeasurementResult });

    // Copy dress type dress patterns
    const dressTypeDressPatternResult = await copyCollection(
      DressTypeDressPattern1,
      MasterDressTypeDressPattern,
      'dresstypedresspattern_1',
      'masterdresstypedresspattern'
    );
    results.push({ collection: 'dresstypedresspattern', ...dressTypeDressPatternResult });

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 COPY SUMMARY');
    console.log('='.repeat(60));
    
    results.forEach(result => {
      if (result.skipped) {
        console.log(`   ${result.collection}: ⚠️  Skipped (source not found or empty)`);
      } else if (result.error) {
        console.log(`   ${result.collection}: ❌ Error - ${result.error}`);
      } else {
        console.log(`   ${result.collection}: ✅ Copied ${result.copied} documents`);
      }
    });

    const totalCopied = results.reduce((sum, r) => sum + (r.copied || 0), 0);
    const totalSkipped = results.filter(r => r.skipped).length;
    const totalErrors = results.filter(r => r.error).length;

    console.log('\n' + '='.repeat(60));
    console.log(`Total: ${totalCopied} documents copied`);
    if (totalSkipped > 0) {
      console.log(`Skipped: ${totalSkipped} collections`);
    }
    if (totalErrors > 0) {
      console.log(`Errors: ${totalErrors} collections`);
    }
    console.log('='.repeat(60));

    // Show sample records
    console.log('\n📋 Sample Records:');
    const db = mongoose.connection.db;
    
    for (const result of results) {
      if (result.copied > 0) {
        let sampleModel, collectionName;
        switch (result.collection) {
          case 'measurements':
            sampleModel = MasterMeasurement;
            collectionName = 'mastermeasurements';
            break;
          case 'dresspatterns':
            sampleModel = MasterDressPattern;
            collectionName = 'masterdresspatterns';
            break;
          case 'dresstypemeasurements':
            sampleModel = MasterDressTypeMeasurement;
            collectionName = 'masterdresstypemeasurements';
            break;
          case 'dresstypedresspattern':
            sampleModel = MasterDressTypeDressPattern;
            collectionName = 'masterdresstypedresspattern';
            break;
        }
        
        if (sampleModel) {
          const sample = await sampleModel.findOne().lean();
          console.log(`\n   ${collectionName}:`);
          console.log(JSON.stringify(sample, null, 4));
        }
      }
    }

    await mongoose.connection.close();
    console.log('\n🔌 Disconnected from MongoDB');
    console.log('\n✅ Master data copy completed!');
  } catch (error) {
    console.error('❌ Error during copy:', error);
    process.exit(1);
  }
}

// Run the copy
copyAllMasterData();

