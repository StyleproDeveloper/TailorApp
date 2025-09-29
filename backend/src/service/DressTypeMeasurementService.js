const mongoose = require('mongoose');
const DressTypeMeasurement = require('../models/DressTypeMeasurementModel');
const DressTypeSchema = require('../models/DressTypeModel').schema;
const MeasurementSchema = require('../models/MeasurementModel').schema;
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists, getDynamicModelShop } = require('../utils/Helper');
const { getCollectionBasedonShop } = require('../utils/DynamicModel');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');

const getDreessTypeMeaasurementModel = (shop_id) => {
  const collectionName = `dressTypeMeasurement_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, DressTypeMeasurement.schema, collectionName)
  );
};

// **Create DressTypeMeasurement**
const createDressTypeMeasurementService = async (dressPatternDataArray) => {
  try {
    if (
      !Array.isArray(dressPatternDataArray) ||
      dressPatternDataArray.length === 0
    ) {
      throw new Error('Invalid input: Expected an array of dress pattern data');
    }

    const results = [];
    for (const DressTypeData of dressPatternDataArray) {
      const { shop_id, dressTypeId, measurementId, ...data } = DressTypeData;
      // Check if shop exists
      const shopExists = await isShopExists(shop_id);
      if (!shopExists)
        throw new Error(`Shop with ID ${shop_id} does not exist`);
      const collectionName = getCollectionBasedonShop('dressType', shop_id);
      const DressTypeModel = mongoose.connection.model(
        collectionName,
        DressTypeSchema
      );
      // Query using dressTypeId field (not _id)
      const dressType = await DressTypeModel.find({
        dressTypeId: Number(dressTypeId),
      });
      if (!dressType) {
        throw new Error(
          `DressType with ID ${dressTypeId} does not exist in collection ${collectionName}`
        );
      }

      const measurementCollection = getCollectionBasedonShop(
        'measurement',
        shop_id
      );
      const MeasurementModel = mongoose.connection.model(
        measurementCollection,
        MeasurementSchema
      );

      // Query using measurementId field (not _id)
      const measurement = await MeasurementModel.find({
        measurementId: Number(measurementId),
      });
      if (!measurement) {
        throw new Error(
          `Measurement with ID ${measurementId} does not exist in collection ${measurementCollection}`
        );
      }

      const DressTypeMeasurementModel = getDreessTypeMeaasurementModel(shop_id);

      // Create and save the new pattern
      const newPattern = {
        dressTypeMeasurementId: await getNextSequenceValue(
          'dressTypeMeasurementId'
        ),
        dressTypeId: Number(dressTypeId), // Add this
        measurementId: Number(measurementId), // Add this
        shop_id: Number(shop_id),
        ...data,
      };
      const result = await DressTypeMeasurementModel.insertMany(newPattern);
      results.push(result);
    }

    return results;
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
};

// **Get all dresstypeMeasurements**
const getAllDressTypeMeasurementService = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    // Get the correct dynamic model for DressTypeMeasurement
    const DressTypeMeasurementModel = getDreessTypeMeaasurementModel(shop_id);

    const searchableFields = ['name', 'owner']; // you can add more if needed
    const numericFields = ['dressTypeMeasurementId', 'shop_id']; // adjust if needed

    // Use common buildQueryOptions
    const options = buildQueryOptions(
      queryParams,
      'createdAt', // default sort field
      searchableFields,
      numericFields
    );

    const query = { ...options?.search, ...options?.booleanFilters };

    const dressTypeMeasurements = await DressTypeMeasurementModel.aggregate([
      { $match: query },
      {
        $lookup: {
          from: `dressType_${shop_id}`,
          let: { dressTypeId: '$dressTypeId' },
          pipeline: [
            {
              $match: {
                $expr: { $eq: ['$dressTypeId', '$$dressTypeId'] },
              },
            },
            { $project: { name: 1, _id: 0 } },
          ],
          as: 'dressType',
        },
      },
      {
        $lookup: {
          from: `measurement_${shop_id}`,
          let: { measurementId: '$measurementId' },
          pipeline: [
            {
              $match: {
                $expr: { $eq: ['$measurementId', '$$measurementId'] },
              },
            },
            { $project: { name: 1, _id: 0 } },
          ],
          as: 'measurement',
        },
      },
      {
        $unwind: {
          path: '$dressType',
          preserveNullAndEmptyArrays: true,
        },
      },
      {
        $unwind: {
          path: '$measurement',
          preserveNullAndEmptyArrays: true,
        },
      },
      {
        $project: {
          _id: 1,
          dressTypeMeasurementId: 1,
          shop_id: 1,
          dressTypeId: 1,
          dressTypeName: { $ifNull: ['$dressType.name', 'Not Found'] },
          measurementId: 1,
          measurementName: { $ifNull: ['$measurement.name', 'Not Found'] },
          owner: 1,
          createdAt: 1,
          updatedAt: 1,
        },
      },
    ]);

    // Pass everything to common paginate
    return await paginate(DressTypeMeasurementModel, query, {
      ...options,
      data: dressTypeMeasurements,
    });
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
};

// **Get expense by ID**
const getDressTypeMeasurementByIdService = async (
  shop_id,
  dressTypeMeasurementId
) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const DressTypeMeasurementModel = getDreessTypeMeaasurementModel(shop_id);
    return await DressTypeMeasurementModel.findOne({
      dressTypeMeasurementId: Number(dressTypeMeasurementId),
    });
  } catch (error) {
    throw error;
  }
};

// **Update expense**
// const updateDressTypeMeasurementService = async (
//   shop_id,
//   dressTypeMeasurementId,
//   DressTypeData
// ) => {
//   try {
//     if (!shop_id) throw new Error('Shop ID is required');

//     const shopExists = await isShopExists(shop_id);
//     if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

//     const DressTypeMeasurementModel = getDreessTypeMeaasurementModel(shop_id);
//     return await DressTypeMeasurementModel.findOneAndUpdate(
//       { dressTypeMeasurementId: Number(dressTypeMeasurementId) },
//       DressTypeData,
//       { new: true }
//     );
//   } catch (error) {
//     throw error;
//   }
// };

const updateDressTypeMeasurementService = async (updatesArray) => {
  try {
    if (!Array.isArray(updatesArray) || updatesArray.length === 0) {
      throw new Error('Expected a non-empty array of updates');
    }

    const results = [];

    for (const updateData of updatesArray) {
      const { shop_id, dressTypeMeasurementId, ...updateFields } = updateData;

      const shopExists = await isShopExists(shop_id);
      if (!shopExists) {
        throw new Error(`Shop with ID ${shop_id} does not exist`);
      }

      const DressTypeMeasurementModel = getDreessTypeMeaasurementModel(shop_id);

      const updated = await DressTypeMeasurementModel.findOneAndUpdate(
        { dressTypeMeasurementId: Number(dressTypeMeasurementId) },
        updateFields,
        { new: true }
      );

      if (!updated) {
        throw new Error(
          `Record not found with ID ${dressTypeMeasurementId} for shop ${shop_id}`
        );
      }

      results.push(updated);
    }

    return results;
  } catch (error) {
    console.error('Error in updateDressTypeMeasurementService:', error);
    throw error;
  }
};

// **Delete expense**
const deleteDressTypeMeasurementService = async (
  shop_id,
  dressTypeMeasurementId
) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const DressTypeMeasurementModel = getDreessTypeMeaasurementModel(shop_id);
    return await DressTypeMeasurementModel.findOneAndDelete({
      dressTypeMeasurementId: Number(dressTypeMeasurementId),
    });
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createDressTypeMeasurementService,
  getAllDressTypeMeasurementService,
  getDressTypeMeasurementByIdService,
  updateDressTypeMeasurementService,
  deleteDressTypeMeasurementService,
};
