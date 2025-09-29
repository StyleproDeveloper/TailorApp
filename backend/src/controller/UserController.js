const { create } = require('lodash');
const {
  createUserService,
  getAllUserService,
  getUserByIdService,
  updateUserService,
  deleteuserService,
} = require('../service/UserService');

const CreateUser = async (req, res) => {
  try {
    const CreateUser = await createUserService(req.body);
    res.status(201).json({
      message: 'User Created Successfully',
      CreateUser,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getUser = async (req, res) => {
  try {
    const user = await getAllUserService(req?.query);
    res.status(200).json(user);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getUserById = async (req, res) => {
  try {
    const user = await getUserByIdService(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateUser = async (req, res) => {
  try {
    const user = await updateUserService(req.params.id, req.body);
    if (!user) return res.status(404).json({ error: 'user not found' });
    res.status(200).json({ message: 'user updated successfully', user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteUser = async (req, res) => {
  try {
    const user = await deleteuserService(req.params.id);
    res.status(200).json({ message: 'user deleted successfully', user });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  CreateUser,
  getUser,
  getUserById,
  updateUser,
  deleteUser,
};
