const mongoose = require('mongoose');
const Expense = require('../models/ExpenseModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');

const getExpenseModel = (shop_id) => {
  const collectionName = `expense_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Expense.schema, collectionName)
  );
};

// **Create Expense**
const createExpenseService = async (expenseData) => {
  try {
    const { shop_id, ...data } = expenseData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const ExpenseModel = getExpenseModel(shop_id);
    const expenseId = await getNextSequenceValue('expenseId');

    const newExpense = new ExpenseModel({ expenseId, shop_id, ...data });
    return await newExpense.save();
  } catch (error) {
    throw error;
  }
};

// **Get all expenses**
const getAllExpenseService = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const ExpenseModel = getExpenseModel(shop_id);
    const searchbleFields = ['name', 'owner'];
    const numericFields = ['expenseId', 'shop_id'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'name',
      searchbleFields,
      numericFields
    );
    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(ExpenseModel, query, options);
  } catch (error) {
    throw error;
  }
};

// **Get expense by ID**
const getExpenseByIdService = async (shop_id, expenseId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const ExpenseModel = getExpenseModel(shop_id);
    return await ExpenseModel.findOne({ expenseId: Number(expenseId) });
  } catch (error) {
    throw error;
  }
};

// **Update expense**
const updateExpenseService = async (shop_id, expenseId, expenseData) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const ExpenseModel = getExpenseModel(shop_id);
    return await ExpenseModel.findOneAndUpdate(
      { expenseId: Number(expenseId) },
      expenseData,
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

// **Delete expense**
const deleteExpenseService = async (shop_id, expenseId) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const ExpenseModel = getExpenseModel(shop_id);
    return await ExpenseModel.findOneAndDelete({
      expenseId: Number(expenseId),
    });
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createExpenseService,
  getAllExpenseService,
  getExpenseByIdService,
  updateExpenseService,
  deleteExpenseService,
};
