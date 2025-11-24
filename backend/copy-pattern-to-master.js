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

const copyToMaster = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const targetCollection = 'masterdresstypedresspattern';
    
    // Get all collection names
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    console.log('\n🔍 Searching for source collections...\n');
    
    // Try to find shop 1 collection with various name patterns
    const possibleSources = [
      'dressTypeDressPattern_1',
      'dresstypedresspattern_1',
      'dressTypeDressPatterns_1',
      'dresstypedresspatterns_1',
    ];
    
    let sourceCollection = null;
    let sourceDocs = [];
    
    // Check each possible source
    for (const sourceName of possibleSources) {
      if (collectionNames.includes(sourceName)) {
        const count = await db.collection(sourceName).countDocuments();
        console.log(`✅ Found: ${sourceName} (${count} documents)`);
        if (count > 0) {
          sourceCollection = sourceName;
          sourceDocs = await db.collection(sourceName).find({}).toArray();
          break;
        }
      }
    }
    
    // If not found, check for any collection with pattern and _1
    if (!sourceCollection) {
      const shop1Patterns = collectionNames.filter(name => {
        const lower = name.toLowerCase();
        return (lower.includes('dresstype') && lower.includes('pattern')) && name.includes('_1');
      });
      
      for (const name of shop1Patterns) {
        const count = await db.collection(name).countDocuments();
        console.log(`✅ Found: ${name} (${count} documents)`);
        if (count > 0) {
          sourceCollection = name;
          sourceDocs = await db.collection(name).find({}).toArray();
          break;
        }
      }
    }
    
    if (!sourceCollection || sourceDocs.length === 0) {
      console.error('\n❌ No source collection found with data!');
      console.log('\n📋 Available collections:');
      collectionNames
        .filter(name => name.toLowerCase().includes('pattern') || name.includes('_1'))
        .forEach(name => {
          db.collection(name).countDocuments().then(count => {
            if (count > 0) {
              console.log(`   - ${name} (${count} documents)`);
            }
          });
        });
      process.exit(1);
    }
    
    console.log(`\n📋 Copying ${sourceDocs.length} documents from ${sourceCollection} to ${targetCollection}...`);
    
    // Show sample document
    if (sourceDocs.length > 0) {
      console.log('\n📄 Sample source document:');
      console.log(JSON.stringify(sourceDocs[0], null, 2));
    }
    
    // Clear target collection if it exists
    if (collectionNames.includes(targetCollection)) {
      const existingCount = await db.collection(targetCollection).countDocuments();
      if (existingCount > 0) {
        console.log(`\n🗑️ Clearing ${existingCount} existing documents from ${targetCollection}...`);
        await db.collection(targetCollection).deleteMany({});
      }
    }
    
    // Prepare documents for insertion
    const documentsToInsert = sourceDocs.map((doc) => {
      const { _id, __v, createdAt, updatedAt, ...rest } = doc;
      
      // Map fields - handle both old and new formats
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
          // Duplicate key error
          skippedCount++;
          console.log(`⚠️ Skipping duplicate: dressTypePatternId=${doc.dressTypePatternId}`);
        } else {
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
    console.log(`\n✅ Verification: ${targetCollection} now has ${finalCount} documents`);
    
    if (finalCount > 0) {
      const sample = await db.collection(targetCollection).findOne({});
      console.log('\n📄 Sample copied document:');
      console.log(JSON.stringify(sample, null, 2));
    }
    
    console.log('\n✅ Copy operation completed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

copyToMaster();

