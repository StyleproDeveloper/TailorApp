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

const checkShop1 = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    // Check if shop 1 exists
    const shop1 = await db.collection('shopinfos').findOne({ shop_id: 1 });
    
    if (shop1) {
      console.log('\n✅ Shop 1 exists:');
      console.log(`   Shop Name: ${shop1.shopName || shop1.yourName}`);
      console.log(`   Shop ID: ${shop1.shop_id}`);
    } else {
      console.log('\n❌ Shop 1 does not exist in shopinfos collection');
    }
    
    // Check all collections for shop 1
    const allCollections = await db.listCollections().toArray();
    const shop1Collections = allCollections
      .map(c => c.name)
      .filter(name => name.includes('_1'));
    
    console.log(`\n📋 Collections with "_1" (shop 1): ${shop1Collections.length}`);
    if (shop1Collections.length > 0) {
      shop1Collections.forEach(name => console.log(`   - ${name}`));
    } else {
      console.log('   (none found)');
    }
    
    // Check if dressTypeDressPattern collection exists for shop 1 (any variation)
    const patternCollections = allCollections
      .map(c => c.name)
      .filter(name => {
        const lower = name.toLowerCase();
        return (lower.includes('dresstype') && lower.includes('pattern')) && name.includes('_1');
      });
    
    console.log(`\n📋 DressTypeDressPattern collections for shop 1: ${patternCollections.length}`);
    if (patternCollections.length > 0) {
      patternCollections.forEach(name => {
        console.log(`   - ${name}`);
        // Count documents
        db.collection(name).countDocuments().then(count => {
          console.log(`     (${count} documents)`);
        });
      });
    } else {
      console.log('   (none found - collection may need to be created)');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

checkShop1();

