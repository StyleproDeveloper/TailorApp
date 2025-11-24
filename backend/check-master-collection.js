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

const checkMaster = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    console.log('\n🔍 Checking for masterdresstypedresspattern collection...\n');
    
    // Check exact name
    const exactName = 'masterdresstypedresspattern';
    const exists = collectionNames.includes(exactName);
    
    if (exists) {
      const count = await db.collection(exactName).countDocuments();
      console.log(`✅ Collection "${exactName}" exists with ${count} documents`);
      
      if (count > 0) {
        const sample = await db.collection(exactName).findOne({});
        console.log('\n📄 Sample document:');
        console.log(JSON.stringify(sample, null, 2));
      }
    } else {
      console.log(`❌ Collection "${exactName}" does not exist`);
      
      // Check for similar names
      const similar = collectionNames.filter(name => 
        name.toLowerCase().includes('master') && 
        name.toLowerCase().includes('pattern')
      );
      
      if (similar.length > 0) {
        console.log('\n📋 Similar collections found:');
        similar.forEach(name => console.log(`   - ${name}`));
      }
    }
    
    // List all collections for reference
    console.log('\n📋 All collections in database:');
    collectionNames.forEach(name => console.log(`   - ${name}`));
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

checkMaster();

