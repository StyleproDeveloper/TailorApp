const Measurements = require('../models/MeasurementModel');
const { getNextSequenceValue } = require('./sequenceService');
const mongoose = require('mongoose');
const { isShopExists } = require('../utils/Helper');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');

const getMeaasurementModel = (shop_id) => {
  const collectionName = `measurement_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Measurements.schema, collectionName)
  );
};

const createMeasurementService = async (measurementData) => {
  try {
    const { shop_id, ...data } = measurementData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const MeasurementModel = getMeaasurementModel(shop_id);
    const measurementId = await getNextSequenceValue('measurementId');

    const newMeasurement = new MeasurementModel({
      measurementId,
      shop_id,
      ...data,
    });
    return await newMeasurement.save();
  } catch (error) {
    throw error;
  }
};

const getAllMeasurements = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const MeasurementModel = getMeaasurementModel(shop_id);
    const searchbleFields = ['name', 'owner'];
    const numericFields = ['measurementId', 'shop_id'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );
    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(MeasurementModel, query, options);
  } catch (error) {
    throw error;
  }
};

const getMeasurementByIdService = async (shop_id, measurementId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const MeasurementModel = getMeaasurementModel(shop_id);
    return await MeasurementModel.findOne({
      measurementId: Number(measurementId),
    });
  } catch (error) {
    throw error;
  }
};

const updateMeasurementService = async (
  shop_id,
  measurementId,
  measurementData
) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const MeasurementModel = getMeaasurementModel(shop_id);
    return await MeasurementModel.findOneAndUpdate(
      { measurementId: Number(measurementId) },
      measurementData,
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

const deleteMeasurementService = async (shop_id, measurementId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const MeasurementModel = getMeaasurementModel(shop_id);
    return await MeasurementModel.findOneAndDelete({
      measurementId: Number(measurementId),
    });
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createMeasurementService,
  getAllMeasurements,
  getMeasurementByIdService,
  updateMeasurementService,
  deleteMeasurementService,
};
