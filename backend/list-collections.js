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

const listCollections = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const collections = await db.listCollections().toArray();
    
    console.log('\n📋 All collections in database:');
    console.log('='.repeat(50));
    
    // Filter for dress type pattern related collections
    const patternCollections = collections.filter(col => 
      col.name.toLowerCase().includes('dress') && 
      col.name.toLowerCase().includes('pattern')
    );
    
    console.log('\n🎨 Dress Type Pattern related collections:');
    patternCollections.forEach(col => {
      console.log(`  - ${col.name}`);
    });
    
    // Also show shop-specific collections
    const shopCollections = collections.filter(col => 
      col.name.includes('_1') || col.name.includes('_99')
    );
    
    console.log('\n🏪 Shop-specific collections (sample):');
    shopCollections.slice(0, 10).forEach(col => {
      console.log(`  - ${col.name}`);
    });
    
    console.log(`\n📊 Total collections: ${collections.length}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error listing collections:', error);
    process.exit(1);
  }
};

listCollections();

