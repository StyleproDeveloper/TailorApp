const {
  getOrderDressTypeMeaPatternService,
} = require('../service/OrderDressTypeMeaPatternService');

const getOrderDressTypeMeaPattern = async (req, res) => {
  try {
    const { shop_id, dressTypeId } = req.params;
    if (!shop_id || !dressTypeId)
      return res
        .status(400)
        .json({ error: 'Shop ID and DressType ID are required' });

    const data = await getOrderDressTypeMeaPatternService(shop_id, dressTypeId);
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

module.exports = { getOrderDressTypeMeaPattern };
