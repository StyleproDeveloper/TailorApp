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
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(DressTypeModel, query, options);
  } catch (error) {
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
