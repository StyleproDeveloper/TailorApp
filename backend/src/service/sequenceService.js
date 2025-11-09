const Sequence = require('../models/SequenceModel');
const mongoose = require('mongoose');

/**
 * Get the maximum value from a collection for a given field
 */
const getMaxValueFromCollection = async (collectionName, fieldName) => {
  try {
    const db = mongoose.connection.db;
    const collection = db.collection(collectionName);
    const result = await collection
      .find({})
      .sort({ [fieldName]: -1 })
      .limit(1)
      .toArray();
    
    return result.length > 0 ? (result[0][fieldName] || 0) : 0;
  } catch (error) {
    // Collection doesn't exist or error, return 0
    return 0;
  }
};

/**
 * Initialize sequence from existing data if collection exists
 */
const initializeSequenceFromExisting = async (sequenceName, shopId, branchId) => {
  // Only initialize for orderId sequences
  if (sequenceName !== 'orderId') {
    return null;
  }

  try {
    const collectionName = `order_${shopId}`;
    const maxOrderId = await getMaxValueFromCollection(collectionName, 'orderId');
    
    if (maxOrderId > 0) {
      // Collection exists and has orders, return max + 1 as starting point
      return maxOrderId;
    }
  } catch (error) {
    // Collection doesn't exist, will start from 0
  }
  
  return null;
};

const getNextSequenceValue = async (sequenceName, shopId = null, branchId = null) => {
  // Create shop-specific sequence name if shopId is provided
  let finalSequenceName = sequenceName;
  if (shopId !== null && shopId !== undefined) {
    if (branchId !== null && branchId !== undefined) {
      // Include branchId in sequence name for branch-specific sequences
      finalSequenceName = `${sequenceName}_shop_${shopId}_branch_${branchId}`;
    } else {
      // Shop-specific sequence (no branch)
      finalSequenceName = `${sequenceName}_shop_${shopId}`;
    }
  }

  // Check if sequence already exists
  let existingSequence = await Sequence.findOne({ name: finalSequenceName });
  
  // If sequence doesn't exist and it's an orderId, try to initialize from existing data
  if (!existingSequence && sequenceName === 'orderId' && shopId) {
    const maxExistingValue = await initializeSequenceFromExisting(sequenceName, shopId, branchId);
    
    if (maxExistingValue !== null && maxExistingValue > 0) {
      // Initialize sequence with max existing value
      existingSequence = await Sequence.create({
        name: finalSequenceName,
        value: maxExistingValue,
      });
    }
  }

  // Increment and return
  const sequenceDocument = await Sequence.findOneAndUpdate(
    { name: finalSequenceName },
    { $inc: { value: 1 } },
    { new: true, upsert: true } // Create a new document if it doesn't exist
  );

  return sequenceDocument.value;
};

module.exports = { getNextSequenceValue };
