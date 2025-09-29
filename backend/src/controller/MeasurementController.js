const {
  createMeasurementService,
  getAllMeasurements,
  getMeasurementByIdService,
  updateMeasurementService,
  deleteMeasurementService,
} = require('../service/MeasurementService');

const createMeasurement = async (req, res) => {
  try {
    const { shop_id } = req.body;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const createMeasurement = await createMeasurementService({
      ...req.body,
      shop_id,
    });
    res.status(201).json({
      message: 'Measurement Created Successfully',
      createMeasurement,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getMeasurement = async (req, res) => {
  try {
    const { shop_id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const measurement = await getAllMeasurements(shop_id, req?.query);
    res.status(200).json(measurement);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getMeasurementById = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const measurement = await getMeasurementByIdService(shop_id, id);

    if (!measurement)
      return res.status(404).json({ error: 'Measurement not found' });

    res.status(200).json(measurement);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateMeasurement = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const measurement = await updateMeasurementService(shop_id, id, req.body);
    if (!measurement)
      return res.status(404).json({ error: 'Measurement not found' });
    res
      .status(200)
      .json({ message: 'Measurement updated successfully', measurement });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteMeasurement = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const measurement = await deleteMeasurementService(shop_id, id);
    res.status(200).json({ message: 'Measurement deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createMeasurement,
  getMeasurement,
  getMeasurementById,
  updateMeasurement,
  deleteMeasurement,
};
