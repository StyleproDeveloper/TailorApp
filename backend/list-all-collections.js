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

const listAll = async () => {
  try {
    await connectDB();
    const db = mongoose.connection.db;
    
    const collections = await db.listCollections().toArray();
    
    console.log('\n📋 All collections in database:\n');
    collections.forEach((col, index) => {
      console.log(`${index + 1}. ${col.name}`);
    });
    
    console.log(`\n📊 Total: ${collections.length} collections\n`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

listAll();

