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

const checkData = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    // Check dresstypedresspatterns collection
    const count = await db.collection('dresstypedresspatterns').countDocuments();
    console.log(`\n📊 Documents in 'dresstypedresspatterns': ${count}`);
    
    if (count > 0) {
      const sample = await db.collection('dresstypedresspatterns').findOne({});
      console.log('\n📄 Sample document from dresstypedresspatterns:');
      console.log(JSON.stringify(sample, null, 2));
    }
    
    // Check if masterdresstypedresspattern exists
    const collections = await db.listCollections().toArray();
    const masterExists = collections.some(c => c.name === 'masterdresstypedresspattern');
    
    if (masterExists) {
      const masterCount = await db.collection('masterdresstypedresspattern').countDocuments();
      console.log(`\n📊 Documents in 'masterdresstypedresspattern': ${masterCount}`);
    } else {
      console.log('\n📊 Collection "masterdresstypedresspattern" does not exist yet');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

checkData();

