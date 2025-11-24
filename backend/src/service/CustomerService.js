const Customer = require('../models/CustomerModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const mongoose = require('mongoose');
const { paginate } = require('../utils/commonPagination');
const { buildQueryOptions } = require('../utils/buildQuery');
const OrderItemMeasurementSchema =
  require('../models/OrderItemMeasurementModel').schema; // assuming you extracted schema only
const DressTypeSchema = require('../models/DressTypeModel').schema;

const getCustomerModel = (shop_id) => {
  const collectionName = `customer_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Customer.schema, collectionName)
  );
};

function getModelByName(baseName, shopId, schema) {
  const modelName = `${baseName}_${shopId}`;
  return (
    mongoose.models[modelName] || mongoose.model(modelName, schema, modelName)
  );
}

//Create Customer
const createCustomerService = async (customerData) => {
  try {
    const { shop_id, ...data } = customerData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const CustomerModel = getCustomerModel(shop_id);
    // Pass shop_id to getNextSequenceValue to ensure shop-specific customer IDs
    const customerId = await getNextSequenceValue('customerId', shop_id);

    const newCustomer = new CustomerModel({ customerId, shop_id, ...data });
    return await newCustomer.save();
  } catch (error) {
    throw error;
  }
};

//getAll Customer
const getAllCustomerService = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const CustomerModel = getCustomerModel(shop_id);
    const searchbleFields = [
      'name',
      'gender',
      'mobile',
      'secondaryMobile',
      'email',
      'addressLine1',
      'remark',
      'gst',
      'owner',
    ];
    const numericFields = ['customerId', 'branch_id'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };
    return await paginate(CustomerModel, query, options);
  } catch (error) {
    throw error;
  }
};

//searchAllCustomers - Search all customers without pagination for dropdown/search
const searchAllCustomersService = async (shop_id, searchKeyword = '') => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    
    const CustomerModel = getCustomerModel(shop_id);
    
    let query = {};
    
    // If search keyword is provided, search across multiple fields
    if (searchKeyword && searchKeyword.trim() !== '') {
      const searchRegex = { $regex: searchKeyword, $options: 'i' };
      query = {
        $or: [
          { name: searchRegex },
          { mobile: searchRegex },
          { secondaryMobile: searchRegex },
          { email: searchRegex },
          { addressLine1: searchRegex },
          { remark: searchRegex },
          { gst: searchRegex },
          { owner: searchRegex },
        ]
      };
    }
    
    // Get all matching customers, sorted by name
    const customers = await CustomerModel.find(query)
      .sort({ name: 1 })
      .limit(1000); // Limit to prevent performance issues
    
    return {
      success: true,
      data: customers,
      total: customers.length
    };
  } catch (error) {
    throw error;
  }
};

//get Customer by id
const getCustomerByIdService = async (shop_id, customerId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const CustomerModel = getCustomerModel(shop_id);
    return await CustomerModel.findOne({ customerId: Number(customerId) });
  } catch (error) {
    throw error;
  }
};

const getCustomerMeasurementDetails = async (shop_id, customerId) => {
  try {
    const OrderItemMeasurementModel = getModelByName(
      'orderitemmeasurement',
      shop_id,
      OrderItemMeasurementSchema
    );
    const DressTypeModel = getModelByName(
      'dressType',
      shop_id,
      DressTypeSchema
    );

    console.log('customerId', customerId);
    // Get measurements for customer
    const measurements = await OrderItemMeasurementModel.find({ customerId });

    console.log('measurements', measurements);

    // Get all dressType details
    const dressTypeIds = measurements?.map((m) => m?.dressTypeId);
    const dressTypes = await DressTypeModel.find({
      dressTypeId: { $in: dressTypeIds },
    });

    // Combine measurement with dressType details
    const result = measurements?.map((measure) => {
      const dressType = dressTypes?.find(
        (dt) => dt.dressTypeId === measure.dressTypeId
      );

      return {
        ...measure.toObject(),
        dressType: dressType || null,
      };
    });

    return result;
  } catch (err) {
    console.error(err);
    throw err;
  }
};

//update Customer
const updateCustomerService = async (shop_id, customerId, customerData) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const CustomerModel = getCustomerModel(shop_id);
    return await CustomerModel.findOneAndUpdate(
      { customerId: Number(customerId) },
      customerData,
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

//Delete Customer
const deleteCustomerService = async (shop_id, customerId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const CustomerModel = getCustomerModel(shop_id);
    return await CustomerModel.findOneAndDelete(customerId);
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createCustomerService,
  getAllCustomerService,
  searchAllCustomersService,
  getCustomerByIdService,
  updateCustomerService,
  deleteCustomerService,
  getCustomerMeasurementDetails,
};
