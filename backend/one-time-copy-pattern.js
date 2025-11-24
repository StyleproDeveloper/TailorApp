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

const oneTimeCopy = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const targetCollection = 'masterdresstypedresspattern';
    const sourceCollection = 'dressTypeDressPattern_1';
    
    console.log('\n🔄 ONE-TIME DATA MOVEMENT');
    console.log('   Source: dressTypeDressPattern_1');
    console.log('   Target: masterdresstypedresspattern\n');
    
    // Get all collections
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    // Find source collection (try all variations)
    const sourceVariations = [
      'dressTypeDressPattern_1',
      'dresstypedresspattern_1',
      'dressTypeDressPatterns_1',
      'dresstypedresspatterns_1',
    ];
    
    let actualSource = null;
    for (const name of sourceVariations) {
      if (collectionNames.includes(name)) {
        actualSource = name;
        break;
      }
    }
    
    // Also check for any collection with pattern and _1
    if (!actualSource) {
      const shop1Patterns = collectionNames.filter(name => {
        const lower = name.toLowerCase();
        return (lower.includes('dresstype') && lower.includes('pattern')) && 
               name.includes('_1');
      });
      if (shop1Patterns.length > 0) {
        actualSource = shop1Patterns[0];
      }
    }
    
    if (!actualSource) {
      console.log('❌ Source collection "dressTypeDressPattern_1" not found');
      console.log('\n📋 Checking all collections...');
      collectionNames.forEach(name => {
        if (name.toLowerCase().includes('pattern') || name.includes('_1')) {
          db.collection(name).countDocuments().then(count => {
            if (count > 0) {
              console.log(`   - ${name}: ${count} documents`);
            }
          });
        }
      });
      
      // Ensure target collection exists
      if (!collectionNames.includes(targetCollection)) {
        await db.collection(targetCollection).insertOne({ _temp: true });
        await db.collection(targetCollection).deleteMany({ _temp: true });
        console.log(`\n✅ Created ${targetCollection} collection (empty)`);
      } else {
        const count = await db.collection(targetCollection).countDocuments();
        console.log(`\n✅ ${targetCollection} exists with ${count} documents`);
      }
      
      console.log('\n💡 Source collection will be created when shop 1 is set up.');
      console.log('   Once data exists, run this script again to copy it.');
      process.exit(0);
    }
    
    console.log(`✅ Found source: ${actualSource}`);
    
    // Get documents
    const sourceDocs = await db.collection(actualSource).find({}).toArray();
    console.log(`📊 Found ${sourceDocs.length} documents`);
    
    if (sourceDocs.length === 0) {
      console.log('⚠️ Source collection is empty');
      process.exit(0);
    }
    
    // Ensure target exists
    if (!collectionNames.includes(targetCollection)) {
      await db.collection(targetCollection).insertOne({ _temp: true });
      await db.collection(targetCollection).deleteMany({ _temp: true });
      console.log(`✅ Created ${targetCollection} collection`);
    }
    
    // Clear target
    const existing = await db.collection(targetCollection).countDocuments();
    if (existing > 0) {
      console.log(`🗑️ Clearing ${existing} existing documents from target...`);
      await db.collection(targetCollection).deleteMany({});
    }
    
    // Prepare and insert documents
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
    
    console.log(`\n📤 Copying ${documentsToInsert.length} documents...`);
    
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
    
    const finalCount = await db.collection(targetCollection).countDocuments();
    
    console.log(`\n✅ ONE-TIME COPY COMPLETED`);
    console.log(`   Inserted: ${inserted} documents`);
    if (skipped > 0) console.log(`   Skipped: ${skipped} duplicates`);
    console.log(`   Total in ${targetCollection}: ${finalCount} documents`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

oneTimeCopy();

