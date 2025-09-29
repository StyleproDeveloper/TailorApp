const mongoose = require('mongoose');
const BillingTerms = require('../models/BillingTermsModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { paginate } = require('../utils/commonPagination');
const { buildQueryOptions } = require('../utils/buildQuery');

const getBillingTermModel = (shop_id) => {
  const collectionName = `billingTerms_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, BillingTerms.schema, collectionName)
  );
};

// **Create BillingTerms**
const createBillingTerms = async (billingTermData) => {
  try {
    const { shop_id, ...data } = billingTermData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const BillingtermModel = getBillingTermModel(shop_id);
    const billingTermId = await getNextSequenceValue('billingTermId');

    const newBillingtermModel = new BillingtermModel({
      billingTermId,
      shop_id,
      ...data,
    });
    return await newBillingtermModel.save();
  } catch (error) {
    throw error;
  }
};

// **Get all billingTerms**
const getAllBillingTermsService = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const BillingtermModel = getBillingTermModel(shop_id);
    const searchbleFields = [
      'terms',
      'gst_no',
      'gst_state',
      'gst_address',
      'owner',
    ];
    const numericFields = ['billingTermId', 'shop_id'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'terms',
      searchbleFields,
      numericFields
    );
    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(BillingtermModel, query, options);
  } catch (error) {
    throw error;
  }
};

// **Get billing Term by ID**
const getBillingTermByIdService = async (shop_id, billingTermId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const BillingtermModel = getBillingTermModel(shop_id);
    return await BillingtermModel.findOne({
      billingTermId: Number(billingTermId),
    });
  } catch (error) {
    throw error;
  }
};

// **Update billing Term**
const updateBillingTermService = async (
  shop_id,
  billingTermId,
  billingTermData
) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const BillingtermModel = getBillingTermModel(shop_id);
    return await BillingtermModel.findOneAndUpdate(
      { billingTermId: Number(billingTermId) },
      billingTermData,
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

// **Delete billing Term**
const deleteBillingTermService = async (shop_id, billingTermId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const BillingtermModel = getBillingTermModel(shop_id);
    return await BillingtermModel.findOneAndDelete({
      billingTermId: Number(billingTermId),
    });
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createBillingTerms,
  getAllBillingTermsService,
  getBillingTermByIdService,
  updateBillingTermService,
  deleteBillingTermService,
};
