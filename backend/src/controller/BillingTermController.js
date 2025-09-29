const {
  createBillingTerms,
  getAllBillingTermsService,
  getBillingTermByIdService,
  updateBillingTermService,
  deleteBillingTermService,
} = require('../service/BillingTermService');

const createBillingTerm = async (req, res) => {
  try {
    const { shop_id } = req.body; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const billingTerm = await createBillingTerms(req.body);
    res.status(201).json({
      message: 'Billing Term Created Successfully',
      data: billingTerm,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getBillingTerm = async (req, res) => {
  try {
    const { shop_id } = req.params; // Get shop_id from URL params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const billingTerm = await getAllBillingTermsService(shop_id, req?.query);
    res.status(200).json(billingTerm);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getBillingTermById = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const billingTerm = await getBillingTermByIdService(shop_id, id);
    if (!billingTerm)
      return res.status(404).json({ error: 'Billing Term not found' });

    res.status(200).json(billingTerm);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateBillingTerm = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const billingTerm = await updateBillingTermService(shop_id, id, req.body);
    if (!billingTerm)
      return res.status(404).json({ error: 'Billing Term not found' });

    res
      .status(200)
      .json({
        message: 'Billing Term updated successfully',
        data: billingTerm,
      });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteBillingTerm = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const billingTerm = await deleteBillingTermService(shop_id, id);
    if (!billingTerm)
      return res.status(404).json({ error: 'Billing Term not found' });

    res.status(200).json({ message: 'Billing Term deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createBillingTerm,
  getBillingTerm,
  getBillingTermById,
  updateBillingTerm,
  deleteBillingTerm,
};
