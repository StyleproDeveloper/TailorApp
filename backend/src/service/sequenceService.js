const Sequence = require('../models/SequenceModel');

const getNextSequenceValue = async (sequenceName) => {
  const sequenceDocument = await Sequence.findOneAndUpdate(
    { name: sequenceName },
    { $inc: { value: 1 } },
    { new: true, upsert: true } // Create a new document if it doesn't exist
  );

  return sequenceDocument.value;
};

module.exports = { getNextSequenceValue };
