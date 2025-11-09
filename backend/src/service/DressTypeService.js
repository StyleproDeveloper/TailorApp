const dressType = require('../models/DressTypeModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const mongoose = require('mongoose');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');

const getDressTYpeModel = (shop_id) => {
  const collectionName = `dressType_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, dressType.schema, collectionName)
  );
};

//Create user
const createDressTypeService = async (dressTypeData) => {
  try {
    const { shop_id, ...data } = dressTypeData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const DressTypeModel = getDressTYpeModel(shop_id);
    const dressTypeId = await getNextSequenceValue('dressTypeId');
    const newDressType = new DressTypeModel({ dressTypeId, shop_id, ...data });
    return await newDressType.save();
  } catch (error) {
    throw error;
  }
};

//getAll dressType
const gteAllDressTypeService = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressTypeModel = getDressTYpeModel(shop_id);
    const searchbleFields = [ 'name', 'owner'];
    const numericFields = ['dressTypeId', 'shop_id'];
    
    console.log('🔍 DressType search - queryParams:', queryParams);
    console.log('🔍 DressType search - searchKeyword:', queryParams?.searchKeyword);
    
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };
    
    console.log('🔍 DressType search - query:', JSON.stringify(query, null, 2));
    console.log('🔍 DressType search - options:', JSON.stringify({ page: options.page, limit: options.limit }, null, 2));

    const result = await paginate(DressTypeModel, query, options);
    console.log(`🔍 DressType search - found ${result.data.length} results (total: ${result.total})`);
    
    return result;
  } catch (error) {
    console.error('🔍 DressType search error:', error);
    throw error;
  }
};

//get dressType By Id
const getDressTypeByIdService = async (shop_id, dressTypeId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressTypeModel = getDressTYpeModel(shop_id);
    return await DressTypeModel.findOne({ dressTypeId: Number(dressTypeId) });
  } catch (error) {
    throw error;
  }
};

//update user
const updateDressTypeService = async (shop_id, dressTypeId, dressTypeData) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressTypeModel = getDressTYpeModel(shop_id);
    return await DressTypeModel.findOneAndUpdate(
      { dressTypeId: Number(dressTypeId) },
      dressTypeData,
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

//Delete dressType
const deleteDressTypeService = async (shop_id, dressTypeId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressTypeModel = getDressTYpeModel(shop_id);
    return await DressTypeModel.findOneAndDelete({
      dressTypeId: Number(dressTypeId),
    });
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createDressTypeService,
  gteAllDressTypeService,
  getDressTypeByIdService,
  updateDressTypeService,
  deleteDressTypeService,
};
