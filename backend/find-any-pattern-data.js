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

const findAnyPatternData = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    console.log('\n🔍 Searching ALL collections for pattern data...\n');
    
    // Check every collection for documents that might contain pattern data
    for (const colName of collectionNames) {
      try {
        const count = await db.collection(colName).countDocuments();
        if (count > 0) {
          // Sample a few documents to see structure
          const samples = await db.collection(colName).find({}).limit(3).toArray();
          
          // Check if any sample has pattern-related fields
          const hasPatternFields = samples.some(doc => {
            const keys = Object.keys(doc);
            return keys.some(key => 
              key.toLowerCase().includes('pattern') ||
              key.toLowerCase().includes('dresstype') ||
              key === 'dressTypeId' ||
              key === 'dressPatternId' ||
              key === 'DressType_ID' ||
              key === 'DressPattern_ID'
            );
          });
          
          if (hasPatternFields) {
            console.log(`\n✅ ${colName}: ${count} documents (has pattern-related fields)`);
            console.log('   Sample:', JSON.stringify(samples[0], null, 2).substring(0, 300));
          }
        }
      } catch (err) {
        // Skip if can't read
      }
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

findAnyPatternData();

