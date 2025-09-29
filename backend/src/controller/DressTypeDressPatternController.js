const {
  createDTDPService,
  getDTDPByIdService,
  gteAllDTDPservice,
  updateDTDPService,
  deleteDTDPService,
} = require('../service/DressTypeDressPatternService');

const createDressTypeDressPattern = async (req, res) => {
  try {
    const dressPatternDataArray = req.body;

    if (
      !Array.isArray(dressPatternDataArray) ||
      dressPatternDataArray.length === 0
    ) {
      return res
        .status(400)
        .json({ error: 'Invalid input: Expected an array of objects' });
    }

    const createdDressPatterns = await createDTDPService(dressPatternDataArray);

    res.status(201).json({
      message: 'Dress Type Dress Patterns Created Successfully',
      data: createdDressPatterns,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getDressTypeDressPattern = async (req, res) => {
  try {
    const { shop_id } = req.params; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressType = await gteAllDTDPservice(shop_id, req?.query);
    res.status(200).json(dressType);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getDressTypeDressPatternById = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressType = await getDTDPByIdService(shop_id, id);

    if (!dressType)
      return res
        .status(404)
        .json({ error: 'Dress Type Dress Pattern not found' });

    res.status(200).json(dressType);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateDressTypeDressPattern = async (req, res) => {
  try {
    const updates = req?.body;

    const updatedPatterns = await updateDTDPService(updates);

    res.status(200).json({
      message: 'Dress Type Dress Patterns updated successfully',
      data: updatedPatterns,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteDressTypeDressPattern = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressType = await deleteDTDPService(shop_id, id);
    if (!dressType)
      return res.status(404).json({ error: 'Dress Type not found' });
    res.status(200).json({ message: 'Dress Type deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createDressTypeDressPattern,
  getDressTypeDressPattern,
  getDressTypeDressPatternById,
  updateDressTypeDressPattern,
  deleteDressTypeDressPattern,
};
