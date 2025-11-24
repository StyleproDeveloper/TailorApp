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

const findCollections = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const collections = await db.listCollections().toArray();
    
    console.log('\n🔍 Searching for pattern-related collections...\n');
    
    // Find all collections with "pattern" in the name
    const patternCollections = collections.filter(col => 
      col.name.toLowerCase().includes('pattern')
    );
    
    console.log('📋 Pattern-related collections:');
    patternCollections.forEach(col => {
      console.log(`  - ${col.name}`);
    });
    
    // Find collections with "_1" (shop 1)
    const shop1Collections = collections.filter(col => 
      col.name.includes('_1')
    );
    
    console.log('\n🏪 Shop 1 collections:');
    shop1Collections.forEach(col => {
      console.log(`  - ${col.name}`);
    });
    
    // Find master collections
    const masterCollections = collections.filter(col => 
      col.name.toLowerCase().includes('master')
    );
    
    console.log('\n📚 Master collections:');
    masterCollections.forEach(col => {
      console.log(`  - ${col.name}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

findCollections();

