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

const findAllPatternCollections = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    // Get all collections
    const allCollections = await db.listCollections().toArray();
    const collectionNames = allCollections.map(c => c.name);
    
    console.log('\n🔍 Searching for all DressTypeDressPattern collections...\n');
    
    // Find all collections that might contain pattern data
    const patternCollections = collectionNames.filter(name => {
      const lower = name.toLowerCase();
      return (lower.includes('dresstype') && lower.includes('pattern')) || 
             (lower.includes('pattern') && name.includes('_'));
    });
    
    if (patternCollections.length === 0) {
      console.log('❌ No pattern collections found');
    } else {
      console.log(`📋 Found ${patternCollections.length} potential pattern collections:\n`);
      
      for (const colName of patternCollections) {
        const count = await db.collection(colName).countDocuments();
        if (count > 0) {
          console.log(`✅ ${colName}: ${count} documents`);
          
          // Show sample
          const sample = await db.collection(colName).findOne({});
          console.log(`   Sample:`, JSON.stringify(sample, null, 2).substring(0, 200) + '...');
        } else {
          console.log(`   ${colName}: 0 documents (empty)`);
        }
      }
    }
    
    // Also check all shops
    const shops = await db.collection('shopinfos').find({}).toArray();
    console.log(`\n📊 Shops in database: ${shops.length}`);
    shops.forEach(shop => {
      console.log(`   - Shop ID: ${shop.shop_id}, Name: ${shop.shopName || shop.yourName}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

findAllPatternCollections();

