const {
  createUserBarnchService,
  getAllUserBranchs,
  getUserBranchByIdService,
  updateUserBranchService,
  deleteUserBranchService,
} = require('../service/UserBranchService');

const createUserBranch = async (req, res) => {
  try {
    const { shop_id } = req.body; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const userBranch = await createUserBarnchService(req.body);
    res.status(201).json({
      message: 'User Branch Created Successfully',
      data: userBranch,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getUserBranch = async (req, res) => {
  try {
    const { shop_id } = req.params; // Get shop_id from URL params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const userBranches = await getAllUserBranchs(shop_id, req?.query);
    res.status(200).json(userBranches);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getUserBranchId = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const userBranch = await getUserBranchByIdService(shop_id, id);
    if (!userBranch)
      return res.status(404).json({ error: 'User Branch not found' });

    res.status(200).json(userBranch);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateUserBranch = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const userBranch = await updateUserBranchService(shop_id, id, req.body);
    if (!userBranch)
      return res.status(404).json({ error: 'User Branch not found' });

    res
      .status(200)
      .json({ message: 'User Branch updated successfully', data: userBranch });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteUserBranch = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const userBranch = await deleteUserBranchService(shop_id, id);
    if (!userBranch)
      return res.status(404).json({ error: 'User Branch not found' });

    res.status(200).json({ message: 'User Branch deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createUserBranch,
  getUserBranch,
  getUserBranchId,
  updateUserBranch,
  deleteUserBranch,
};
