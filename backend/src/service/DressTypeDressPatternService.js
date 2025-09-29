const DressTypeDressPattern = require('../models/DressTypeDresspatternModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const mongoose = require('mongoose');
const { getCollectionBasedonShop } = require('../utils/DynamicModel');
const { paginate } = require('../utils/commonPagination');
const { buildQueryOptions } = require('../utils/buildQuery');
const DressTypeSchema = require('../models/DressTypeModel').schema;
const DressPatternSchema = require('../models/DresspatternModel').schema;

const getDressTypeDressPatternModel = (shop_id) => {
  const collectionName = `dressTypeDressPattern_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, DressTypeDressPattern.schema, collectionName)
  );
};

//Create DressPattern
// const createDTDPService = async (dressPatternData) => {
//   try {
//     const { shop_id, ...data } = dressPatternData;
//     if (!shop_id) throw new Error('Shop ID is required');

//     const shopExists = await isShopExists(shop_id);
//     if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

//     // Validate dressTypeId
//     const dressType = await DressTypeModel.findById(dressTypeId);
//     if (!dressType)
//       throw new Error(`DressType with ID ${dressTypeId} does not exist`);

//     // Validate dressPatternId
//     const dressPattern = await DresspatternModel.findById(dressPatternId);
//     if (!dressPattern)
//       throw new Error(`DressPattern with ID ${dressPatternId} does not exist`);

//     const DressTypeDressPatternModel = getDressTypeDressPatternModel(shop_id);
//     const dressTypePatternId = await getNextSequenceValue('dressTypePatternId');

//     const newDressPattern = new DressTypeDressPatternModel({
//       dressTypePatternId,
//       shop_id,
//       ...data,
//     });
//     return await newDressPattern.save();
//   } catch (error) {
//     throw error;
//   }
// };
const createDTDPService = async (dressPatternDataArray) => {
  try {
    if (
      !Array.isArray(dressPatternDataArray) ||
      dressPatternDataArray.length === 0
    ) {
      throw new Error('Invalid input: Expected an array of dress pattern data');
    }
    const results = [];
    // Validate all records in the array
    for (const data of dressPatternDataArray) {
      const { dressTypeId, dressPatternId, shop_id } = data;

      if (!shop_id) throw new Error('Shop ID is required');

      const shopExists = await isShopExists(shop_id);
      if (!shopExists)
        throw new Error(`Shop with ID ${shop_id} does not exist`);

      const collectionName = getCollectionBasedonShop('dressType', shop_id);
      const DressTypeModel = mongoose.connection.model(
        collectionName,
        DressTypeSchema
      );

      console.log('dressTypeId', dressTypeId);
      console.log('DressTypeModel', DressTypeModel);
      // Query using dressTypeId field (not _id)
      const dressType = await DressTypeModel.find({
        dressTypeId: Number(dressTypeId),
      });

      console.log('DressType query result:', dressType); // Debug log

      if (!dressType) {
        throw new Error(
          `DressType with ID ${dressTypeId} does not exist in collection ${collectionName}`
        );
      }

      const dressPatternCollection = getCollectionBasedonShop(
        'dresspattern',
        shop_id
      );
      const DresspatternModel = mongoose.connection.model(
        dressPatternCollection,
        DressPatternSchema
      );

      // Make sure to use the correct field name here too (dressPatternId)
      const dressPattern = await DresspatternModel.find({
        dressPatternId: Number(dressPatternId),
      });

      if (!dressPattern) {
        throw new Error(
          `DressPattern with ID ${dressPatternId} does not exist in collection ${dressPatternCollection}`
        );
      }
      // Get the model for current shop
      const DressTypeDressPatternModel = getDressTypeDressPatternModel(shop_id);

      // Create and save the new pattern
      const newPattern = {
        dressTypePatternId: await getNextSequenceValue('dressTypePatternId'),
        ...data,
      };
      // Insert multiple records using insertMany
      const result = await DressTypeDressPatternModel.insertMany(newPattern);
      results.push(result);
    }

    return results;
  } catch (error) {
    console.error('Error in createDTDPService:', error);
    throw error;
  }
};

//getAll DressPattern
const gteAllDTDPservice = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressTypeDressPatternModel = getDressTypeDressPatternModel(shop_id);
    const searchbleFields = ['category', 'owner'];
    const numericFields = ['dressTypeId', 'dressTypeId', 'dressPatternId'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'category',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(DressTypeDressPatternModel, query, options);
  } catch (error) {
    throw error;
  }
};

//get DressPattern by id
const getDTDPByIdService = async (shop_id, dressTypePatternId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressTypeDressPatternModel = getDressTypeDressPatternModel(shop_id);
    return await DressTypeDressPatternModel.findOne({
      dressTypePatternId: Number(dressTypePatternId),
    });
  } catch (error) {
    throw error;
  }
};

//update DressPattern
// const updateDTDPService = async (
//   shop_id,
//   dressTypePatternId,
//   dressPatternData
// ) => {
//   try {
//     if (!shop_id) throw new Error('Shop ID is required');

//     const shopExists = await isShopExists(shop_id);
//     if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
//     const DressTypeDressPatternModel = getDressTypeDressPatternModel(shop_id);
//     return await DressTypeDressPatternModel.findOneAndUpdate(
//       { dressTypePatternId: Number(dressTypePatternId) },
//       dressPatternData,
//       { new: true }
//     );
//   } catch (error) {
//     throw error;
//   }
// };

const updateDTDPService = async (updatesArray) => {
  try {
    if (!Array.isArray(updatesArray) || updatesArray.length === 0) {
      throw new Error('Invalid input: Expected a non-empty array of updates');
    }

    const results = [];

    for (const updateData of updatesArray) {
      const { shop_id, dressTypePatternId, ...updateFields } = updateData;

      console.log('updateFields', updateFields); // Debug log

      const shopExists = await isShopExists(shop_id);
      if (!shopExists) {
        throw new Error(`Shop with ID ${shop_id} does not exist`);
      }

      const DressTypeDressPatternModel = getDressTypeDressPatternModel(shop_id);

      const existDressPattern = await DressTypeDressPatternModel.findOne({
        dressTypePatternId: Number(dressTypePatternId),
      });

      if (!existDressPattern) {
        throw new Error(
          `No record found with dressTypePatternId ${dressTypePatternId} in shop ${shop_id}`
        );
      }

      const updated = await DressTypeDressPatternModel.findOneAndUpdate(
        { dressTypePatternId: Number(dressTypePatternId) },
        updateFields,
        { new: true }
      );

      if (!updated) {
        throw new Error(
          `No record found with dressTypePatternId ${dressTypePatternId} in shop ${shop_id}`
        );
      }

      results.push(updated);
    }

    return results;
  } catch (error) {
    console.error('Error in updateDTDPService:', error);
    throw error;
  }
};

//Delete DressPattern
const deleteDTDPService = async (shop_id, dressTypePatternId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);
    const DressTypeDressPatternModel = getDressTypeDressPatternModel(shop_id);
    return await DressTypeDressPatternModel.findOneAndDelete(
      dressTypePatternId
    );
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createDTDPService,
  gteAllDTDPservice,
  getDTDPByIdService,
  updateDTDPService,
  deleteDTDPService,
};
