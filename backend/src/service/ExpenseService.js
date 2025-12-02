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
    const { shop_id, entries, ...data } = expenseData;
    if (!shop_id) throw new Error('Shop ID is required');

    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const ExpenseModel = getExpenseModel(shop_id);
    const expenseId = await getNextSequenceValue('expenseId');

    // Convert date strings to Date objects in entries array
    let processedEntries = [];
    if (entries && Array.isArray(entries) && entries.length > 0) {
      processedEntries = entries.map(entry => {
        const processedEntry = { ...entry };
        // Convert date string to Date object if it's a string
        if (entry.date && typeof entry.date === 'string') {
          processedEntry.date = new Date(entry.date);
        }
        return processedEntry;
      });
    }

    // Auto-generate name from first entry's expenseType and date if not provided
    let expenseName = data.name;
    if (!expenseName || expenseName.trim() === '') {
      if (processedEntries.length > 0 && processedEntries[0].expenseType && processedEntries[0].date) {
        const firstEntry = processedEntries[0];
        const expenseType = firstEntry.expenseType.charAt(0).toUpperCase() + firstEntry.expenseType.slice(1);
        const entryDate = firstEntry.date instanceof Date ? firstEntry.date : new Date(firstEntry.date);
        const dateStr = entryDate.toISOString().split('T')[0]; // Format as YYYY-MM-DD
        expenseName = `${expenseType} ${dateStr}`;
      } else {
        // Fallback if no entries
        expenseName = `Expense ${new Date().toISOString().split('T')[0]}`;
      }
    }

    const newExpense = new ExpenseModel({ 
      expenseId, 
      shop_id, 
      ...data,
      name: expenseName,
      entries: processedEntries.length > 0 ? processedEntries : []
    });
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
    const numericFields = ['expenseId', 'shop_id', 'rent', 'electricity', 'salary', 'miscellaneous'];
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
    
    // Convert date strings to Date objects in entries array if present
    const { entries, ...otherData } = expenseData;
    let updateData = { ...otherData };
    
    if (entries && Array.isArray(entries) && entries.length > 0) {
      updateData.entries = entries.map(entry => {
        const processedEntry = { ...entry };
        // Convert date string to Date object if it's a string
        if (entry.date && typeof entry.date === 'string') {
          processedEntry.date = new Date(entry.date);
        }
        return processedEntry;
      });
      
      // Auto-generate name from first entry if name is not provided or empty
      if (!updateData.name || updateData.name.trim() === '') {
        const firstEntry = updateData.entries[0];
        if (firstEntry.expenseType && firstEntry.date) {
          const expenseType = firstEntry.expenseType.charAt(0).toUpperCase() + firstEntry.expenseType.slice(1);
          const entryDate = firstEntry.date instanceof Date ? firstEntry.date : new Date(firstEntry.date);
          const dateStr = entryDate.toISOString().split('T')[0]; // Format as YYYY-MM-DD
          updateData.name = `${expenseType} ${dateStr}`;
        }
      }
    }
    
    return await ExpenseModel.findOneAndUpdate(
      { expenseId: Number(expenseId) },
      updateData,
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
