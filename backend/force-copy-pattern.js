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

const forceCopy = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const targetCollection = 'masterdresstypedresspattern';
    const sourceCollection = 'dressTypeDressPattern_1'; // Exact name user specified
    
    console.log('\n🔍 One-time data movement: dressTypeDressPattern_1 → masterdresstypedresspattern\n');
    
    // Check if source exists
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    // Try exact name first
    let actualSource = null;
    if (collectionNames.includes(sourceCollection)) {
      actualSource = sourceCollection;
    } else {
      // Try case variations
      const variations = [
        'dressTypeDressPattern_1',
        'dresstypedresspattern_1',
        'dressTypeDressPatterns_1',
        'dresstypedresspatterns_1',
      ];
      
      for (const varName of variations) {
        if (collectionNames.includes(varName)) {
          actualSource = varName;
          break;
        }
      }
    }
    
    if (!actualSource) {
      console.error(`❌ Source collection "${sourceCollection}" not found!`);
      console.log('\n📋 Available collections:');
      collectionNames.forEach(name => console.log(`   - ${name}`));
      console.log('\n💡 The collection will be created when shop 1 is set up.');
      console.log('   If you have data elsewhere, please specify the collection name.');
      process.exit(1);
    }
    
    console.log(`✅ Found source: ${actualSource}`);
    
    // Get all documents
    const sourceDocs = await db.collection(actualSource).find({}).toArray();
    console.log(`📊 Found ${sourceDocs.length} documents to copy`);
    
    if (sourceDocs.length === 0) {
      console.log('⚠️ Source collection is empty - nothing to copy');
      process.exit(0);
    }
    
    // Show sample
    console.log('\n📄 Sample source document:');
    console.log(JSON.stringify(sourceDocs[0], null, 2));
    
    // Clear target if exists
    if (collectionNames.includes(targetCollection)) {
      const existing = await db.collection(targetCollection).countDocuments();
      if (existing > 0) {
        console.log(`\n🗑️ Clearing ${existing} existing documents from target...`);
        await db.collection(targetCollection).deleteMany({});
      }
    }
    
    // Prepare documents
    const documentsToInsert = sourceDocs.map((doc) => {
      const { _id, __v, createdAt, updatedAt, ...rest } = doc;
      
      return {
        dressTypeId: doc.dressTypeId ?? doc.DressType_ID ?? null,
        dressPatternId: doc.dressPatternId ?? doc.DressPattern_ID ?? null,
        dressTypePatternId: doc.dressTypePatternId ?? doc.Id ?? null,
        category: doc.category ?? doc.Category ?? null,
        owner: doc.owner ?? null,
      };
    });
    
    console.log(`\n📤 Inserting ${documentsToInsert.length} documents into ${targetCollection}...`);
    
    // Insert all documents
    let inserted = 0;
    let skipped = 0;
    
    for (const doc of documentsToInsert) {
      try {
        await db.collection(targetCollection).insertOne(doc);
        inserted++;
      } catch (err) {
        if (err.code === 11000) {
          skipped++;
        } else {
          throw err;
        }
      }
    }
    
    console.log(`\n✅ Successfully inserted: ${inserted} documents`);
    if (skipped > 0) {
      console.log(`⚠️ Skipped duplicates: ${skipped} documents`);
    }
    
    // Final verification
    const finalCount = await db.collection(targetCollection).countDocuments();
    console.log(`\n✅ masterdresstypedresspattern now contains ${finalCount} documents`);
    
    if (finalCount > 0) {
      const sample = await db.collection(targetCollection).findOne({});
      console.log('\n📄 Sample copied document:');
      console.log(JSON.stringify(sample, null, 2));
    }
    
    console.log('\n✅ One-time data movement completed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

forceCopy();

