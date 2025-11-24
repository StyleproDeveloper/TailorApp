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
    // Support both old format (DressType_ID, Measurement) and new format (dressTypeId, name)
    const measurements = await MeasurementModel.find({
      $or: [
        { dressTypeId: Number(dressTypeId) },
        { DressType_ID: Number(dressTypeId) },
      ],
    });
    
    // Map measurements to consistent format
    // Support both old format (DressType_ID, Measurement) and new format (dressTypeId, name)
    const formattedMeasurements = measurements.map((m) => {
      const doc = m.toObject ? m.toObject() : m;
      return {
        dressTypeMeasurementId: doc.dressTypeMeasurementId || null,
        dressTypeId: doc.dressTypeId !== undefined ? doc.dressTypeId : (doc.DressType_ID !== undefined ? doc.DressType_ID : null),
        name: doc.name || doc.Measurement || doc.measurement || '',
        measurementId: doc.measurementId !== undefined ? doc.measurementId : (doc.Measurement_ID !== undefined ? doc.Measurement_ID : null),
      };
    });

    // Fetch DressType-DressPattern Relations - include category field (lowercase c)
    const dressTypeDressPatterns = await DressTypePatternModel.find({
      dressTypeId: Number(dressTypeId),
    }).select('Id dressTypeId dressPatternId category Category _id').lean();

    console.log(`🎨 Found ${dressTypeDressPatterns.length} dress type pattern relations`);

    // Convert `dressPatternId` to Number (if necessary)
    const patternIds = dressTypeDressPatterns.map((item) =>
      Number(item.dressPatternId)
    ).filter(id => id > 0);

    console.log(`🎨 Pattern IDs to fetch: ${patternIds.join(', ')}`);

    // Fetch DressPattern Details - fetch ALL fields to see what actually exists
    const dressPatterns = await DressPatternModel.find({
      dressPatternId: { $in: patternIds },
    }).lean();

    console.log(`🎨 Found ${dressPatterns.length} pattern details`);
    
    // Log the first pattern to see ALL fields
    if (dressPatterns.length > 0) {
      console.log(`🎨 Sample pattern (all fields):`, JSON.stringify(dressPatterns[0], null, 2));
    }

    // Create a map for faster lookup
    const patternMap = new Map();
    dressPatterns.forEach((p) => {
      const id = Number(p.dressPatternId);
      
      // Check ALL possible field names - the database might have DressPattern, dressPattern, or name
      // Handle name as array or string
      let rawName = p.DressPattern || p.dressPattern || p.name || p.Name || null;
      
      // If name is an array, extract the first element
      if (Array.isArray(rawName)) {
        rawName = rawName.length > 0 ? rawName[0] : null;
      }
      
      // Convert to string and trim
      const patternName = rawName ? String(rawName).trim() : `Pattern ${id}`;
      
      // Handle category - check both Category (capital C) and category (lowercase c) from dresspattern table
      let patternCategory = p.Category || p.category || '';
      if (patternCategory && Array.isArray(patternCategory)) {
        patternCategory = patternCategory.length > 0 ? String(patternCategory[0]).trim() : '';
      } else if (patternCategory) {
        patternCategory = String(patternCategory).trim();
      }
      
      console.log(`🎨 Pattern ${id} from dresspattern: Category=${p.Category}, category=${p.category}, finalCategory="${patternCategory}"`);
      
      patternMap.set(id, {
        _id: p._id?.toString() || '',
        dressPatternId: id,
        name: patternName,
        category: patternCategory, // Will be merged with dressTypeDressPattern category below
        selection: p.selection || 'multiple',
      });
    });

    // Format response with proper PatternDetails
    // Merge category from dressTypeDressPattern (lowercase c) with patternDetails from dresspattern (Category/category)
    const formattedPatterns = dressTypeDressPatterns.map((dp) => {
      // dp is already a plain object since we used .lean()
      const dressPatternId = Number(dp.dressPatternId);
      const patternDetails = patternMap.get(dressPatternId);

      // Get category from dressTypeDressPattern table (lowercase c, but also check Category with capital C)
      let relationCategory = dp.category || dp.Category || '';
      if (relationCategory && Array.isArray(relationCategory)) {
        relationCategory = relationCategory.length > 0 ? String(relationCategory[0]).trim() : '';
      } else if (relationCategory) {
        relationCategory = String(relationCategory).trim();
      }

      // Merge: prefer category from dressTypeDressPattern, fallback to dresspattern category
      let finalCategory = relationCategory || (patternDetails?.category || '');
      if (!finalCategory) {
        finalCategory = 'Other';
      }

      console.log(`🎨 Pattern ${dressPatternId}: relationCategory="${relationCategory}", patternCategory="${patternDetails?.category}", finalCategory="${finalCategory}"`);

      if (!patternDetails) {
        console.warn(`⚠️ Pattern details not found for dressPatternId=${dressPatternId}`);
        return {
          _id: dp._id?.toString() || dp.Id?.toString() || '',
          Id: dp.Id,
          dressTypeId: dp.dressTypeId,
          dressPatternId: dressPatternId,
          PatternDetails: {
            _id: '',
            dressPatternId: dressPatternId,
            name: 'Unnamed Pattern',
            category: finalCategory,
            selection: 'multiple',
          },
        };
      }

      // Merge patternDetails with category from relation
      return {
        _id: dp._id?.toString() || dp.Id?.toString() || '',
        Id: dp.Id,
        dressTypeId: dp.dressTypeId,
        dressPatternId: dressPatternId,
        PatternDetails: {
          ...patternDetails,
          category: finalCategory, // Use merged category
        },
      };
    });

    console.log(`🎨 Returning ${formattedPatterns.length} formatted patterns`);

    return {
      DressTypeMeasurement: formattedMeasurements,
      DressTypeDressPattern: formattedPatterns,
    };
  } catch (error) {
    throw error;
  }
};

module.exports = { getOrderDressTypeMeaPatternService };
