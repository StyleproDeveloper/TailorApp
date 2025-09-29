const {
  createOrderService,
  getAllOrdersService,
  updateOrderService,
} = require('../service/OrderService');

const createOrder = async (req, res) => {
  console.log('req', req.body);
  try {
    const { shop_id } = req?.body?.Order;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const response = await createOrderService(req?.body, shop_id);
    res.status(201).json({
      message: 'Order Created Successfully',
      response,
    });
  } catch (error) {
    res.status(500).json({ message: error?.message });
  }
};

const getAllOrders = async (req, res) => {
  console.log('req', req.query);
  try {
    const { shop_id } = req.params; // Get shop_id from URL params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const response = await getAllOrdersService(shop_id, req?.query);
    console.log('response', response);
    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ message: error?.message });
  }
};

const updateOrder = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const response = await updateOrderService(id, req.body, shop_id);
    if (!response) return res.status(404).json({ error: 'Order not found' });
    res.status(200).json({ message: 'Order updated successfully', response });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createOrder,
  getAllOrders,
  updateOrder,
};
