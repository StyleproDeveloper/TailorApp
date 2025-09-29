const UserBarnch = require('../models/UserBranchModel');
const { getNextSequenceValue } = require('./sequenceService');
const mongoose = require('mongoose');
const { isShopExists } = require('../utils/Helper');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');

const gteUserBranchModel = (shop_id) => {
  const collectionName = `userbranch_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, UserBarnch.schema, collectionName)
  );
};

const createUserBarnchService = async (userBranchData) => {
  try {
    const { shop_id, ...data } = userBranchData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const userBranchModel = gteUserBranchModel(shop_id);
    const userBranchId = await getNextSequenceValue('userBranchId');

    const newUserBranch = new userBranchModel({
      userBranchId,
      shop_id,
      ...data,
    });
    return await newUserBranch.save();
  } catch (error) {
    throw error;
  }
};

const getAllUserBranchs = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const userBranchModel = gteUserBranchModel(shop_id);
    const searchbleFields = ['owner'];
    const numericFields = ['userBranchId', 'userId', 'branchId', 'shop_id'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );
    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(userBranchModel, query, options);
  } catch (error) {
    throw error;
  }
};

const getUserBranchByIdService = async (shop_id, userBranchId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const userBranchModel = gteUserBranchModel(shop_id);
    return await userBranchModel.findOne({
      userBranchId: Number(userBranchId),
    });
  } catch (error) {
    throw error;
  }
};

const updateUserBranchService = async (
  shop_id,
  userBranchId,
  userBranchData
) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const userBranchModel = gteUserBranchModel(shop_id);
    return await userBranchModel.findOneAndUpdate(
      { userBranchId: Number(userBranchId) },
      userBranchData,
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

const deleteUserBranchService = async (shop_id, userBranchId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const userBranchModel = gteUserBranchModel(shop_id);
    return await userBranchModel.findOneAndDelete({
      userBranchId: Number(userBranchId),
    });
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createUserBarnchService,
  getAllUserBranchs,
  getUserBranchByIdService,
  updateUserBranchService,
  deleteUserBranchService,
};
