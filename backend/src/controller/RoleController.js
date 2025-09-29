const {
  createRoleService,
  getAllRoleService,
  getRoleByIdService,
  updateRoleService,
  deleteRoleService,
} = require('../service/RoleService');

const createRole = async (req, res) => {
  try {
    const { shop_id } = req.body; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const createRole = await createRoleService(req.body);
    res.status(201).json({
      message: 'Role Created Successfully',
      createRole,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getRole = async (req, res) => {
  try {
    const { shop_id } = req.params; // Get shop_id from URL params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const role = await getAllRoleService(shop_id, req?.query);
    res.status(200).json(role);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getRoleById = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params

    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const role = await getRoleByIdService(shop_id, id);
    if (!role) return res.status(404).json({ error: 'Role not found' });
    return res.status(200).json(role);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateRole = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const role = await updateRoleService(shop_id, id, req.body);
    if (!role) return res.status(404).json({ error: 'role not found' });
    res.status(200).json({ message: 'role updated successfully', role });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteRole = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });
    const role = await deleteRoleService(shop_id, id);
    if (!role) return res.status(404).json({ error: 'role not found' });
    res.status(200).json({ message: 'role deleted successfully', role });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createRole,
  getRole,
  getRoleById,
  updateRole,
  deleteRole,
};
