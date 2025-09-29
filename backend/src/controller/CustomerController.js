const {
  createCustomerService,
  getAllCustomerService,
  getCustomerByIdService,
  updateCustomerService,
  deleteCustomerService,
  getCustomerMeasurementDetails,
} = require('../service/CustomerService');

const createCustomer = async (req, res) => {
  try {
    const { shop_id } = req.body; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const customer = await createCustomerService(req.body);
    res
      .status(201)
      .json({ message: 'Customer created successfully', customer });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getCustomer = async (req, res) => {
  console.log('getCustomer', req.params);
  try {
    const { shop_id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const customer = await getAllCustomerService(shop_id, req?.query);
    res.status(200).json(customer);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getCustomerById = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const customer = await getCustomerByIdService(shop_id, id);
    if (!customer) return res.status(404).json({ error: 'Customer not found' });
    res.status(200).json(customer);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getCustomerMeasurement = async (req, res) => {
  try {
    const { shop_id, customerId } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const customer = await getCustomerMeasurementDetails(shop_id, customerId);
    if (!customer) return res.status(404).json({ error: 'Customer not found' });
    res.status(200).json(customer);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const updateCustomer = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    const customer = await updateCustomerService(shop_id, id, req.body);
    if (!customer) return res.status(404).json({ error: 'Customer not found' });
    res
      .status(200)
      .json({ message: 'Customer updated successfully', customer });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteCustomer = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    const customer = await deleteCustomerService(shop_id, id);
    res.status(200).json({ message: 'Customer deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createCustomer,
  getCustomer,
  getCustomerById,
  updateCustomer,
  deleteCustomer,
  getCustomerMeasurement,
};
