const User = require('../models/UserModel');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');
const { getNextSequenceValue } = require('./sequenceService');

//Create user
const createUserService = async (userData) => {
  try {
    const userId = await getNextSequenceValue('userId');
    const newUser = new User({
      ...userData,
      userId: userId,
    });
    return await newUser.save();
  } catch (error) {
    throw error;
  }
};

//getAll User
const getAllUserService = async (queryParams) => {
  try {
    // const users = await User.find();
    const searchbleFields = [
      'mobile',
      'name',
      'secondaryMobile',
      'email',
      'addressLine1',
      'street',
      'city',
      // 'postalCode',
    ];
    const numericFields = ['userId', 'branchId', 'roleId', 'postalCode'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(User, query, options);
  } catch (error) {
    throw error;
  }
};

//get User By Id
const getUserByIdService = async (userId) => {
  try {
    return await User.findOne({ userId: userId });
  } catch (error) {
    throw error;
  }
};

//update user
const updateUserService = async (userId, userData) => {
  try {
    // Check if the mobile number exists for another user

    const updatedUser = await User.findOneAndUpdate(
      { userId },
      { $set: userData },
      {
        new: true,
        runValidators: true,
        context: 'query',
      }
    );

    if (!updatedUser) {
      throw new Error(`User with userId ${userId} not found`);
    }

    return updatedUser;
  } catch (error) {
    throw error;
  }
};

//Delete User
const deleteuserService = async (userId) => {
  try {
    return await User.findOneAndDelete(userId);
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createUserService,
  getAllUserService,
  getUserByIdService,
  updateUserService,
  deleteuserService,
};
