// const app = require('./app');
// const mongoose = require('mongoose');
// require('dotenv').config();

// const PORT = process.env.PORT || 5500;
// const MONGO_URL = process.env.MONGO_URL;

// mongoose
//   .connect(MONGO_URL, {
//     connectTimeoutMS: 30000, // 30 seconds
//     socketTimeoutMS: 45000, // 45 seconds
//   })
//   .then(() => {
//     console.log('Connected to MongoDB');
//     app.listen(PORT, () => {
//       console.log(`Server running on port ${PORT}`);
//     });
//   })
//   .catch((err) => {
//     console.error('Failed to connect to MongoDB', err);
//     process.exit(1);
//   });

const app = require('./app');
const mongoose = require('mongoose');
require('dotenv').config();

const PORT = process.env.PORT || 5500;
const MONGO_URL = process.env.MONGO_URL;

if (!MONGO_URL) {
  console.error('❌ MONGO_URL is not defined in the .env file.');
  process.exit(1);
}

mongoose
  .connect(MONGO_URL, {
    connectTimeoutMS: 30000,
    socketTimeoutMS: 45000,
  })
  .then(() => {
    console.log('✅ Connected to MongoDB');
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Failed to connect to MongoDB:', err);
    process.exit(1);
  });

 

