const mongoose = require('mongoose');
require('dotenv').config({ path: './backend/.env' });

const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/tailorapp';
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

const setupMasterPattern = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const targetCollection = 'masterdresstypedresspattern';
    
    // Get all collections
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    console.log('\n🔍 Setting up masterdresstypedresspattern collection...\n');
    
    // Check if target exists
    const targetExists = collectionNames.includes(targetCollection);
    
    // Find source data from any shop
    let sourceCollection = null;
    let sourceDocs = [];
    
    // Check shop-specific collections (any shop number)
    const shopPatternCollections = collectionNames.filter(name => {
      const lower = name.toLowerCase();
      return (lower.includes('dresstype') && lower.includes('pattern')) && 
             /_\d+$/.test(name); // Ends with _number
    });
    
    console.log('🔍 Checking shop-specific collections...');
    for (const colName of shopPatternCollections) {
      const count = await db.collection(colName).countDocuments();
      if (count > 0) {
        console.log(`✅ Found data in: ${colName} (${count} documents)`);
        sourceCollection = colName;
        sourceDocs = await db.collection(colName).find({}).toArray();
        break;
      }
    }
    
    // If no shop-specific data, check general collection
    if (!sourceCollection) {
      const generalCount = await db.collection('dresstypedresspatterns').countDocuments();
      if (generalCount > 0) {
        console.log(`✅ Found data in: dresstypedresspatterns (${generalCount} documents)`);
        sourceCollection = 'dresstypedresspatterns';
        sourceDocs = await db.collection('dresstypedresspatterns').find({}).toArray();
      }
    }
    
    if (!sourceCollection || sourceDocs.length === 0) {
      console.log('\n⚠️ No source data found to copy.');
      console.log('\n📝 Creating empty masterdresstypedresspattern collection...');
      
      // Create collection by inserting an empty document then deleting it
      if (!targetExists) {
        await db.collection(targetCollection).insertOne({ _temp: true });
        await db.collection(targetCollection).deleteMany({ _temp: true });
        console.log('✅ Created masterdresstypedresspattern collection');
      } else {
        console.log('✅ masterdresstypedresspattern collection already exists');
      }
      
      const count = await db.collection(targetCollection).countDocuments();
      console.log(`\n📊 masterdresstypedresspattern now has ${count} documents`);
      console.log('\n💡 To populate it:');
      console.log('   1. Create a shop (e.g., shop 1)');
      console.log('   2. Add dress type pattern data to that shop');
      console.log('   3. Run this script again to copy the data');
      
      process.exit(0);
    }
    
    // We have source data - copy it
    console.log(`\n📋 Copying ${sourceDocs.length} documents from ${sourceCollection} to ${targetCollection}...`);
    
    // Show sample
    if (sourceDocs.length > 0) {
      console.log('\n📄 Sample source document:');
      console.log(JSON.stringify(sourceDocs[0], null, 2));
    }
    
    // Clear target if it exists and has data
    if (targetExists) {
      const existingCount = await db.collection(targetCollection).countDocuments();
      if (existingCount > 0) {
        console.log(`\n🗑️ Clearing ${existingCount} existing documents...`);
        await db.collection(targetCollection).deleteMany({});
      }
    }
    
    // Prepare documents
    const documentsToInsert = sourceDocs.map((doc) => {
      const { _id, __v, createdAt, updatedAt, _temp, ...rest } = doc;
      
      return {
        dressTypeId: doc.dressTypeId ?? doc.DressType_ID ?? null,
        dressPatternId: doc.dressPatternId ?? doc.DressPattern_ID ?? null,
        dressTypePatternId: doc.dressTypePatternId ?? doc.Id ?? null,
        category: doc.category ?? doc.Category ?? null,
        owner: doc.owner ?? null,
      };
    });
    
    console.log(`\n📤 Inserting ${documentsToInsert.length} documents...`);
    
    // Insert documents
    let insertedCount = 0;
    let skippedCount = 0;
    
    for (const doc of documentsToInsert) {
      try {
        await db.collection(targetCollection).insertOne(doc);
        insertedCount++;
      } catch (err) {
        if (err.code === 11000) {
          skippedCount++;
        } else {
          console.error(`❌ Error inserting document:`, err.message);
          throw err;
        }
      }
    }
    
    console.log(`\n✅ Successfully inserted ${insertedCount} documents`);
    if (skippedCount > 0) {
      console.log(`⚠️ Skipped ${skippedCount} duplicate documents`);
    }
    
    // Verify
    const finalCount = await db.collection(targetCollection).countDocuments();
    console.log(`\n✅ masterdresstypedresspattern now has ${finalCount} documents`);
    
    if (finalCount > 0) {
      const sample = await db.collection(targetCollection).findOne({});
      console.log('\n📄 Sample copied document:');
      console.log(JSON.stringify(sample, null, 2));
    }
    
    console.log('\n✅ Setup completed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

setupMasterPattern();

