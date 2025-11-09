const mongoose = require('mongoose');

// Helper function to dynamically create models with custom collection names
const getDynamicModel = async (
  modelName,
  schema,
  collectionName,
  defaultRecords = []
) => {
  // Validate collection name (indirectly validating shopId as well)
  if (
    !collectionName ||
    typeof collectionName !== 'string' ||
    !collectionName.trim() ||
    !collectionName.includes('_')
  ) {
    throw new Error('Invalid collection name: Cannot create model');
  }

  // Prevent model creation if shopId is missing from the collection name
  const [prefix, shopId] = collectionName.split('_');
  if (!shopId || isNaN(parseInt(shopId))) {
    throw new Error('Invalid shopId: Cannot create model');
  }

  let model;
  if (mongoose.connection.models[collectionName]) {
    // Return the existing model if already created
    model = mongoose.connection.models[collectionName];
  } else {
    try {
      // Dynamically create the model
      model = mongoose.connection.model(modelName, schema, collectionName);
    } catch (modelError) {
      // Check if it's a collection limit error
      if (modelError.message && modelError.message.includes('cannot create a new collection')) {
        throw new Error(`Cannot create collection ${collectionName}: ${modelError.message}`);
      }
      throw modelError;
    }
  }

  // Check if the collection is empty and insert default records if provided
  if (defaultRecords && defaultRecords?.length > 0) {
    console.log(
      `Checking for default records in collection: ${collectionName}`,
      defaultRecords
    );
    const recordCount = await model.countDocuments();
    if (recordCount === 0) {
      await model.insertMany(defaultRecords);
      console.log(
        `Default records inserted into collection: ${collectionName}`
      );
    }
  }

  return model;
};

const getCollectionBasedonShop = (collectionPrefix, shop_id) => {
  if (!collectionPrefix || typeof collectionPrefix !== 'string') {
    throw new Error('Invalid collection prefix: Must be a non-empty string.');
  }
  if (!shop_id || isNaN(parseInt(shop_id))) {
    throw new Error('Invalid shop_id: Must be a valid number.');
  }

  return `${collectionPrefix}_${shop_id}`;
};

module.exports = { getDynamicModel, getCollectionBasedonShop };
