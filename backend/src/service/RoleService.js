const { default: mongoose } = require('mongoose');
const Role = require('../models/RoleModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { paginate } = require('../utils/commonPagination');
const { buildQueryOptions } = require('../utils/buildQuery');

const getRoleModel = (shop_id) => {
  const collectionName = `role_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Role.schema, collectionName)
  );
};

//Create user
const createRoleService = async (roleData) => {
  try {
    const { shop_id, ...data } = roleData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const Role = getRoleModel(shop_id);
    const roleId = await getNextSequenceValue('roleId');
    const newRole = new Role({
      ...roleData,
      shop_id: shop_id,
      roleId: roleId,
    });
    return await newRole.save();
  } catch (error) {
    throw error;
  }
};

//getAll Role
const getAllRoleService = async (shop_id, queryParams) => {
  console.log('shop_id', shop_id);
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const Role = getRoleModel(shop_id);
    const searchbleFields = ['name', 'owner'];
    const numericFields = ['roleId', 'shop_id'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };
  return await paginate(Role, query, options);
  } catch (error) {
    throw error;
  }
};
  

//get Role By Id
const getRoleByIdService = async (shop_id, roleId) => {
  console.log('shop_id', shop_id);
  console.log('id', roleId);
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const RoleModel = getRoleModel(shop_id);
    return await RoleModel.findOne({ roleId: Number(roleId) });
  } catch (error) {
    throw error;
  }
};

//update user
const updateRoleService = async (shop_id, roleId, roleData) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const Role = getRoleModel(shop_id);
    return await Role.findOneAndUpdate(
      { roleId: parseInt(roleId) }, // <-- Fix: Use an object for filtering
      roleData,
      { new: true, upsert: true }
    );
  } catch (error) {
    throw error;
  }
};

//Delete Role
const deleteRoleService = async (shop_id, roleId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const Role = getRoleModel(shop_id);
    return await Role.findOneAndDelete(roleId);
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createRoleService,
  getAllRoleService,
  getRoleByIdService,
  updateRoleService,
  deleteRoleService,
};
