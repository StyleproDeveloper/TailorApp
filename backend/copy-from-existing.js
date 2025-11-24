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

const copyFromExisting = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    // Check what shops exist
    const shops = await db.collection('shopinfos').find({}).toArray();
    console.log(`\n📊 Found ${shops.length} shops in database:`);
    shops.forEach(shop => {
      console.log(`   - Shop ID: ${shop.shop_id}, Name: ${shop.shopName || shop.yourName}`);
    });
    
    // Check dresstypedresspatterns collection
    const generalCount = await db.collection('dresstypedresspatterns').countDocuments();
    console.log(`\n📊 Documents in 'dresstypedresspatterns': ${generalCount}`);
    
    // If user wants to copy from shop 1, we need to find which shop has the data
    // or check if they want to copy from the general collection
    
    const targetCollection = 'masterdresstypedresspattern';
    
    if (generalCount > 0) {
      console.log('\n💡 Found data in "dresstypedresspatterns" collection.');
      console.log('   Would you like to copy from this collection instead?');
      console.log('   If yes, I can copy from "dresstypedresspatterns" to "masterdresstypedresspattern"');
    } else {
      console.log('\n⚠️ No data found in "dresstypedresspatterns" either.');
      console.log('   You may need to:');
      console.log('   1. Create shop 1 first');
      console.log('   2. Add data to shop 1\'s collection');
      console.log('   3. Then copy to master collection');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

copyFromExisting();

