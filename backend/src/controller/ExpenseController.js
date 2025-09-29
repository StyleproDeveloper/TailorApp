// const {
//   createExpenseService,
//   getAllexpenseService,
//   getExpenseByIdService,
//   updateExpenseService,
//   deleteExpenseService,
// } = require('../service/ExpenseService');

// const createExpense = async (req, res) => {
//   try {
//     const createExpense = await createExpenseService(req.body);
//     res.status(201).json({
//       message: 'Expense Created Successfully',
//       createExpense,
//     });
//   } catch (error) {
//     res.status(500).json({ error: error?.message });
//   }
// };

// const getExpense = async (req, res) => {
//   try {
//     const expense = await getAllexpenseService();
//     res.status(200).json(expense);
//   } catch (error) {
//     res.status(500).json({ error: error?.message });
//   }
// };

// const getExpenseById = async (req, res) => {
//   try {
//     console.log('Expense ID:', req.params.id); // Debugging log
//     const expense = await getExpenseByIdService(req.params.id);

//     if (!expense) return res.status(404).json({ error: 'Expense not found' });

//     res.status(200).json(expense);
//   } catch (error) {
//     res.status(500).json({ error: error?.message });
//   }
// };

// const updateExpense = async (req, res) => {
//   try {
//     const expense = await updateExpenseService(req.params.expenseId, req.body);
//     if (!expense) return res.status(404).json({ error: 'Expense not found' });
//     res.status(200).json({ message: 'Expense updated successfully', expense });
//   } catch (error) {
//     res.status(500).json({ error: error.message });
//   }
// };

// const deleteExpense = async (req, res) => {
//   try {
//     const expense = await deleteExpenseService(req.params.expenseId);
//     res.status(200).json({ message: 'Expense deleted successfully' });
//   } catch (error) {
//     res.status(500).json({ error: error.message });
//   }
// };

// module.exports = {
//   createExpense,
//   getExpense,
//   getExpenseById,
//   updateExpense,
//   deleteExpense,
// };

const {
  createExpenseService,
  getAllExpenseService,
  getExpenseByIdService,
  updateExpenseService,
  deleteExpenseService,
} = require('../service/ExpenseService');

const createExpense = async (req, res) => {
  try {
    const { shop_id } = req.body; // Get shop_id from request body
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const expense = await createExpenseService(req.body);
    res.status(201).json({
      message: 'Expense Created Successfully',
      data: expense,
    });
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getExpenses = async (req, res) => {
  try {
    const { shop_id } = req.params; // Get shop_id from URL params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const expenses = await getAllExpenseService(shop_id, req?.query);
    res.status(200).json(expenses);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const getExpenseById = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const expense = await getExpenseByIdService(shop_id, id);
    if (!expense) return res.status(404).json({ error: 'Expense not found' });

    res.status(200).json(expense);
  } catch (error) {
    res.status(500).json({ error: error?.message });
  }
};

const updateExpense = async (req, res) => {
  try {
    const { shop_id, id } = req.params; // Get shop_id and expenseId from params
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const expense = await updateExpenseService(shop_id, id, req.body);
    if (!expense) return res.status(404).json({ error: 'Expense not found' });

    res
      .status(200)
      .json({ message: 'Expense updated successfully', data: expense });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteExpense = async (req, res) => {
  try {
    const { shop_id, id } = req.params;
    if (!shop_id) return res.status(400).json({ error: 'Shop ID is required' });

    const expense = await deleteExpenseService(shop_id, id);
    if (!expense) return res.status(404).json({ error: 'Expense not found' });

    res.status(200).json({ message: 'Expense deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createExpense,
  getExpenses,
  getExpenseById,
  updateExpense,
  deleteExpense,
};
