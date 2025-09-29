const mongoose = require('mongoose');
const ShopModel = require('../models/ShopModel');

const isShopExists = async (shop_id) => {
  const shop = await ShopModel.findOne({ shop_id: shop_id });
  return shop !== null;
};

const getDynamicModelShop = (tableName, shop_id, schema) => {
  if (!shop_id) throw new Error('shop_id is required');
  if (!tableName) throw new Error('Table name is required');

  const collectionName = `${tableName}_${shop_id}`; // Generate collection name

  // Check if model already exists to avoid recompiling
  if (mongoose.models[collectionName]) {
    return mongoose.models[collectionName];
  }

  // Create and register a new model dynamically
  return mongoose.model(collectionName, schema, collectionName);
};

module.exports = { isShopExists, getDynamicModelShop };
