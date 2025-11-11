const User = require('../models/UserModel');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');
const { getNextSequenceValue } = require('./sequenceService');
const { getRoleModel } = require('./RoleService');
const mongoose = require('mongoose');

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
    const numericFields = ['userId', 'branchId', 'roleId', 'postalCode', 'shopId'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    // Filter by shopId if provided
    let shopId = null;
    if (queryParams?.shopId) {
      shopId = Number(queryParams.shopId);
      if (!isNaN(shopId)) {
        query.shopId = shopId;
      }
    }

    // If shopId is available, use aggregation to join with roles
    if (shopId && !isNaN(shopId)) {
      const RoleModel = getRoleModel(shopId);
      const roleCollectionName = RoleModel.collection.name;

      // Build aggregation pipeline
      const pipeline = [
        { $match: query },
        {
          $lookup: {
            from: roleCollectionName,
            let: { userRoleId: '$roleId' },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ['$roleId', '$$userRoleId'] },
                },
              },
              { $project: { name: 1, roleId: 1, _id: 0 } },
            ],
            as: 'roleInfo',
          },
        },
        {
          $unwind: {
            path: '$roleInfo',
            preserveNullAndEmptyArrays: true,
          },
        },
        {
          $addFields: {
            roleName: { $ifNull: ['$roleInfo.name', 'Unknown Role'] },
          },
        },
        {
          $project: {
            roleInfo: 0, // Remove the nested roleInfo object
          },
        },
      ];

      // Get total count for pagination
      const totalCount = await User.countDocuments(query);

      // Apply pagination
      const pageNumber = parseInt(options?.pageNumber) || 1;
      const pageSize = parseInt(options?.pageSize) || 10;
      const skip = (pageNumber - 1) * pageSize;

      // Add sort and pagination to pipeline
      if (options?.sortBy) {
        const sortDirection = options?.sortDirection === 'desc' ? -1 : 1;
        pipeline.push({ $sort: { [options.sortBy]: sortDirection } });
      } else {
        pipeline.push({ $sort: { name: 1 } }); // Default sort by name
      }

      pipeline.push({ $skip: skip });
      pipeline.push({ $limit: pageSize });

      // Execute aggregation
      const users = await User.aggregate(pipeline);

      // Return in the same format as paginate function
      return {
        data: users,
        total: totalCount,
        pageSize: pageSize,
        pageNumber: pageNumber,
      };
    } else {
      // If no shopId, use regular pagination (without role lookup)
      return await paginate(User, query, options);
    }
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
