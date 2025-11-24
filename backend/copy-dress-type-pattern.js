const mongoose = require('mongoose');
require('dotenv').config({ path: './backend/.env' });

// Connect to MongoDB
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

const copyDressTypeDressPattern = async () => {
  try {
    await connectDB();

    const db = mongoose.connection.db;
    
    // Try different possible collection names for shop 1
    const possibleSourceNames = [
      'dressTypeDressPattern_1',      // camelCase with underscore
      'dresstypedresspattern_1',     // lowercase with underscore
      'dressTypeDressPatterns_1',    // plural camelCase
      'dresstypedresspatterns_1',    // plural lowercase
    ];
    
    const targetCollection = 'masterdresstypedresspattern';
    
    // Get all collection names
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    console.log('\n🔍 Searching for source collection...');
    
    // Find the actual source collection
    let sourceCollection = null;
    for (const name of possibleSourceNames) {
      if (collectionNames.includes(name)) {
        sourceCollection = name;
        console.log(`✅ Found source collection: ${name}`);
        break;
      }
    }
    
    // Also check for any collection with pattern and _1 (case insensitive)
    if (!sourceCollection) {
      const shop1Pattern = collectionNames.find(name => {
        const lowerName = name.toLowerCase();
        return (lowerName.includes('pattern') || lowerName.includes('dresstype')) && name.includes('_1');
      });
      if (shop1Pattern) {
        sourceCollection = shop1Pattern;
        console.log(`✅ Found source collection: ${shop1Pattern}`);
      }
    }
    
    if (!sourceCollection) {
      console.error('\n❌ Source collection "dressTypeDressPattern_1" not found!');
      console.log('\n📋 Available collections that might be relevant:');
      const relevant = collectionNames.filter(name => 
        name.toLowerCase().includes('pattern') || 
        name.toLowerCase().includes('dresstype') ||
        name.includes('_1')
      );
      if (relevant.length > 0) {
        relevant.forEach(name => console.log(`  - ${name}`));
      } else {
        console.log('  (none found)');
      }
      console.log('\n💡 Tip: Shop-specific collections are created when a shop is set up.');
      console.log('   If shop 1 exists, the collection should be created automatically.');
      process.exit(1);
    }

    console.log(`\n📋 Copying data from ${sourceCollection} to ${targetCollection}...`);

    // Get all documents from source collection
    const sourceDocs = await db.collection(sourceCollection).find({}).toArray();
    console.log(`📊 Found ${sourceDocs.length} documents in ${sourceCollection}`);

    if (sourceDocs.length === 0) {
      console.log('⚠️ No documents to copy - source collection is empty');
      process.exit(0);
    }

    // Show sample document structure
    if (sourceDocs.length > 0) {
      console.log('\n📄 Sample source document:');
      console.log(JSON.stringify(sourceDocs[0], null, 2));
    }

    // Check if target collection exists
    const targetExists = collectionNames.includes(targetCollection);
    if (targetExists) {
      const existingCount = await db.collection(targetCollection).countDocuments();
      console.log(`\n⚠️ Target collection ${targetCollection} already exists with ${existingCount} documents`);
      console.log('🗑️ Clearing existing data in target collection...');
      await db.collection(targetCollection).deleteMany({});
      console.log('✅ Cleared existing data');
    } else {
      console.log(`\n📝 Target collection ${targetCollection} will be created`);
    }

    // Prepare documents for insertion - map fields to match master collection format
    const documentsToInsert = sourceDocs.map((doc) => {
      const { _id, __v, createdAt, updatedAt, ...rest } = doc;
      
      // Map fields - handle both old and new formats
      const mapped = {
        dressTypeId: doc.dressTypeId ?? doc.DressType_ID ?? null,
        dressPatternId: doc.dressPatternId ?? doc.DressPattern_ID ?? null,
        dressTypePatternId: doc.dressTypePatternId ?? doc.Id ?? null,
        category: doc.category ?? doc.Category ?? null,
        owner: doc.owner ?? null,
      };
      
      // Preserve any other fields that might be useful
      Object.keys(rest).forEach(key => {
        if (!['dressTypeId', 'DressType_ID', 'dressPatternId', 'DressPattern_ID', 
              'dressTypePatternId', 'Id', 'category', 'Category', 'owner'].includes(key)) {
          mapped[key] = rest[key];
        }
      });
      
      return mapped;
    });

    console.log(`\n📤 Inserting ${documentsToInsert.length} documents into ${targetCollection}...`);

    // Insert documents into target collection
    if (documentsToInsert.length > 0) {
      try {
        await db.collection(targetCollection).insertMany(documentsToInsert, { ordered: false });
        console.log(`✅ Successfully copied ${documentsToInsert.length} documents`);
      } catch (insertError) {
        // If there are duplicate key errors, try inserting one by one
        if (insertError.code === 11000 || insertError.writeErrors) {
          console.log('⚠️ Some documents may have duplicates, inserting one by one...');
          let successCount = 0;
          let errorCount = 0;
          
          for (const doc of documentsToInsert) {
            try {
              await db.collection(targetCollection).insertOne(doc);
              successCount++;
            } catch (err) {
              if (err.code === 11000) {
                console.log(`⚠️ Skipping duplicate: dressTypePatternId=${doc.dressTypePatternId}`);
                errorCount++;
              } else {
                throw err;
              }
            }
          }
          
          console.log(`✅ Successfully inserted ${successCount} documents`);
          if (errorCount > 0) {
            console.log(`⚠️ Skipped ${errorCount} duplicate documents`);
          }
        } else {
          throw insertError;
        }
      }
    }

    // Verify the copy
    const targetCount = await db.collection(targetCollection).countDocuments();
    console.log(`\n✅ Verification: ${targetCollection} now has ${targetCount} documents`);

    // Show sample of copied data
    if (targetCount > 0) {
      const sample = await db.collection(targetCollection).findOne({});
      console.log('\n📄 Sample copied document:');
      console.log(JSON.stringify(sample, null, 2));
    }

    console.log('\n✅ Copy operation completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error copying data:', error);
    if (error.writeErrors) {
      console.error('Write errors:', error.writeErrors);
    }
    process.exit(1);
  }
};

// Run the copy operation
copyDressTypeDressPattern();
