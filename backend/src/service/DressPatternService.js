const DressPattern = require('../models/DresspatternModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const mongoose = require('mongoose');
const { paginate } = require('../utils/commonPagination');
const { buildQueryOptions } = require('../utils/buildQuery');

const getDressPatternModel = (shop_id) => {
  const collectionName = `dresspattern_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, DressPattern.schema, collectionName)
  );
};

//Create DressPattern
const createDressPatternService = async (dressPatternData) => {
  try {
    const { shop_id, ...data } = dressPatternData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const DressPatternModel = getDressPatternModel(shop_id);
    const dressPatternId = await getNextSequenceValue('dressPatternId');

    const newDressPattern = new DressPatternModel({
      dressPatternId,
      shop_id,
      ...data,
    });
    return await newDressPattern.save();
  } catch (error) {
    throw error;
  }
};

//getAll DressPattern
const getAllDressPatternService = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressPatternModel = getDressPatternModel(shop_id);
    const searchbleFields = ['DressPattern', 'name', 'category', 'selection', 'owner'];
    const numericFields = ['dressPatternId', 'shop_id'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );
    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };
    return await paginate(DressPatternModel, query, options);
  } catch (error) {
    throw error;
  }
};

//get DressPattern by id
const getDressPatternByIdService = async (shop_id, dressPatternId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressPatternModel = getDressPatternModel(shop_id);
    return await DressPatternModel.findOne({
      dressPatternId: Number(dressPatternId),
    });
  } catch (error) {
    throw error;
  }
};

//update DressPattern
const updateDressPatternService = async (
  shop_id,
  dressPatternId,
  dressPatternData
) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressPatternModel = getDressPatternModel(shop_id);
    return await DressPatternModel.findOneAndUpdate(
      { dressPatternId: Number(dressPatternId) },
      dressPatternData,
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

//Delete DressPattern
const deleteDressPatternService = async (shop_id, dressPatternId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressPatternModel = getDressPatternModel(shop_id);
    return await DressPatternModel.findOneAndDelete(dressPatternId);
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createDressPatternService,
  getAllDressPatternService,
  getDressPatternByIdService,
  updateDressPatternService,
  deleteDressPatternService,
};
