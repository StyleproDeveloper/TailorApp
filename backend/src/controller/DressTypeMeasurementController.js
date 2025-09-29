const {
  createDressTypeMeasurementService,
  getAllDressTypeMeasurementService,
  getDressTypeMeasurementByIdService,
  updateDressTypeMeasurementService,
  deleteDressTypeMeasurementService,
} = require('../service/DressTypeMeasurementService');

const createDressTypeMeasurement = async (req, res) => {
  try {
    const dressMeasurementsArray = req.body;

    console.log('dressMeasurementsArray', dressMeasurementsArray);

    if (
      !Array.isArray(dressMeasurementsArray) ||
      dressMeasurementsArray.length === 0
    ) {
      return res
        .status(400)
        .json({ error: 'Invalid input: Expected an array of objects' });
    }

    const DressTypeMeasurement = await createDressTypeMeasurementService(
      dressMeasurementsArray
    );
    res.status(201).json({
      message: 'Dress Type Measurement Created Successfully',
      data: DressTypeMeasurement,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

const getDressTypeMeasurements = async (req, res) => {
  try {
    const { shop_id } = req.params; // Get shop_id from URL params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const DressTypeMeasurements = await getAllDressTypeMeasurementService(
      shop_id,
      req?.query
    );
    res.status(200).json(DressTypeMeasurements);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getDressTypeMeasurementById = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const DressTypeMeasurement = await getDressTypeMeasurementByIdService(
      shop_id,
      id
    );
    if (!DressTypeMeasurement)
      return res
        .status(404)
        .json({ error: 'Dress Type Measurement not found' });

    res.status(200).json(DressTypeMeasurement);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateDressTypeMeasurement = async (req, res) => {
  try {
    const updates = req?.body;

    const updatedItems = await updateDressTypeMeasurementService(updates);

    res.status(200).json({
      message: 'Dress Type Measurements updated successfully',
      data: updatedItems,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteDressTypeMeasurement = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const DressTypeMeasurement = await deleteDressTypeMeasurementService(
      shop_id,
      id
    );
    if (!DressTypeMeasurement)
      return res
        .status(404)
        .json({ error: 'Dress Type Measurement not found' });

    res
      .status(200)
      .json({ message: 'Dress Type Measurement deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createDressTypeMeasurement,
  getDressTypeMeasurements,
  getDressTypeMeasurementById,
  updateDressTypeMeasurement,
  deleteDressTypeMeasurement,
};
