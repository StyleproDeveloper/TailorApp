const mongoose = require('mongoose');
const { isShopExists } = require('../utils/Helper');
const dressTypeMeasurementSchema =
  require('../models/DressTypeMeasurementModel').schema;
const dressTypeDressPatternSchema =
  require('../models/DressTypeDresspatternModel').schema;
const dressPatternSchema = require('../models/DresspatternModel').schema;

const getModel = (shop_id, baseName, schema) => {
  const collectionName = `${baseName}_${shop_id}`;
  console.log('collectionName', collectionName);

  // Ensure schema is valid before using it
  if (!schema || !(schema instanceof mongoose.Schema)) {
    throw new Error(`Invalid schema provided for ${collectionName}`);
  }

  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, schema, collectionName)
  );
};

const getOrderDressTypeMeaPatternService = async (shop_id, dressTypeId) => {
  try {
    if (!shop_id || !dressTypeId)
      throw new Error('Shop ID and DressType ID are required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const MeasurementModel = getModel(
      shop_id,
      'dressTypeMeasurement',
      dressTypeMeasurementSchema
    );
    const DressTypePatternModel = getModel(
      shop_id,
      'dressTypeDressPattern',
      dressTypeDressPatternSchema
    );
    const DressPatternModel = getModel(
      shop_id,
      'dresspattern',
      dressPatternSchema
    );

    // Fetch Measurements
    const measurements = await MeasurementModel.find({
      dressTypeId: dressTypeId,
    }).select('dressTypeMeasurementId dressTypeId name');

    // Fetch DressType-DressPattern Relations
    const dressTypeDressPatterns = await DressTypePatternModel.find({
      dressTypeId: dressTypeId,
    }).select('Id dressTypeId dressPatternId');

    // Convert `dressPatternId` to Number (if necessary)
    const patternIds = dressTypeDressPatterns.map((item) =>
      Number(item.dressPatternId)
    );

    // Fetch DressPattern Details
    const dressPatterns = await DressPatternModel.find({
      dressPatternId: { $in: patternIds },
    }).select('dressPatternId name category selection');

    // Format response
    return {
      DressTypeMeasurement: measurements,
      DressTypeDressPattern: dressTypeDressPatterns.map((dp) => ({
        ...dp.toObject(),
        PatternDetails: dressPatterns.find(
          (p) => p.dressPatternId === dp.dressPatternId
        ), // Ensure proper matching
      })),
    };
  } catch (error) {
    throw error;
  }
};

module.exports = { getOrderDressTypeMeaPatternService };
