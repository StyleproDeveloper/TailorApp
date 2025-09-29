const {
  createDressPatternService,
  getAllDressPatternService,
  getDressPatternByIdService,
  updateDressPatternService,
  deleteDressPatternService,
} = require('../service/DressPatternService');

const createDressPattern = async (req, res) => {
  try {
    const { shop_id } = req.body; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressPattern = await createDressPatternService(req.body);
    res
      .status(201)
      .json({ message: 'DressPattern created successfully', dressPattern });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getDRessPattern = async (req, res) => {
  try {
    const { shop_id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressPattern = await getAllDressPatternService(shop_id, req?.query);
    res.status(200).json(dressPattern);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getDRessPatternById = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressPattern = await getDressPatternByIdService(shop_id, id);
    if (!dressPattern)
      return res.status(404).json({ error: 'DressPattern not found' });
    res.status(200).json(dressPattern);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const updateDresssPattern = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    const dressPattern = await updateDressPatternService(shop_id, id, req.body);
    if (!dressPattern)
      return res.status(404).json({ error: 'DressPattern not found' });
    res
      .status(200)
      .json({ message: 'DressPattern updated successfully', dressPattern });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteDressPattern = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    const dressPattern = await deleteDressPatternService(shop_id, id);
    res.status(200).json({ message: 'DressPattern deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createDressPattern,
  getDRessPattern,
  getDRessPatternById,
  updateDresssPattern,
  deleteDressPattern,
};
