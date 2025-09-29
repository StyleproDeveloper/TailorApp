const {
  createDressTypeService,
  gteAllDressTypeService,
  getDressTypeByIdService,
  updateDressTypeService,
  deleteDressTypeService,
} = require('../service/DressTypeService');

const createDressType = async (req, res) => {
  try {
    const { shop_id } = req.body; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const createDressType = await createDressTypeService(req.body);
    res.status(201).json({
      message: 'Dress Type Created Successfully',
      createDressType,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getDressType = async (req, res) => {
  try {
    const { shop_id } = req.params; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressType = await gteAllDressTypeService(shop_id, req?.query);
    res.status(200).json(dressType);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getDressTypeById = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressType = await getDressTypeByIdService(shop_id, id);

    if (!dressType)
      return res.status(404).json({ error: 'Dress Type not found' });

    res.status(200).json(dressType);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateDressType = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressType = await updateDressTypeService(shop_id, id, req.body);
    if (!dressType)
      return res.status(404).json({ error: 'Dress Type not found' });
    res
      .status(200)
      .json({ message: 'Dress Type updated successfully', dressType });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteDressType = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const dressType = await deleteDressTypeService(shop_id, id);
    if (!dressType)
      return res.status(404).json({ error: 'Dress Type not found' });
    res.status(200).json({ message: 'Dress Type deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createDressType,
  getDressType,
  getDressTypeById,
  updateDressType,
  deleteDressType,
};
