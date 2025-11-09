const Sequence = require('../models/SequenceModel');

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

  const sequenceDocument = await Sequence.findOneAndUpdate(
    { name: finalSequenceName },
    { $inc: { value: 1 } },
    { new: true, upsert: true } // Create a new document if it doesn't exist
  );

  return sequenceDocument.value;
};

module.exports = { getNextSequenceValue };
