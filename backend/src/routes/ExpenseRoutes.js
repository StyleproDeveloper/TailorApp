const express = require('express');
const router = express.Router();
const {
  createExpense,
  getExpenses,
  getExpenseById,
  updateExpense,
  deleteExpense,
} = require('../controller/ExpenseController');
const validateRequest = require('../middlewares/validateRequest');
const { createExpenseSchema, updateExpenseSchema } = require('../validations/ExpenseValidation');

/**
 * @swagger
 * tags:
 *   name: Expenses
 *   description: Expense APIs
 */

/**
 * @swagger
 * /expense:
 *   post:
 *     summary: Create a new expense
 *     tags: [Expenses]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               shop_id:
 *                 type: number
 *               name:
 *                 type: string
 *               owner:
 *                 type: string
 *     responses:
 *       201:
 *         description: Expense created successfully
 */
router.post('/', validateRequest(createExpenseSchema), createExpense);

/**
 * @swagger
 * /expense/{shop_id}:
 *   get:
 *     summary: Get all expenses for a specific shop
 *     tags: [Expenses]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: pageNumber
 *         schema:
 *           type: integer
 *         description: Page number (default is 1)
 *         example: 1
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *         description: Number of items per page (default is 10)
 *         example: 10
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *         description: Sort by field (default is createdAt)
 *       - in: query
 *         name: sortDirection
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *         description: Sorting order (asc for ascending, desc for descending)
 *       - in: query
 *         name: searchKeyword
 *         schema:
 *           type: string
 *         description: Search keyword
 *     responses:
 *       200:
 *         description: List of expenses
 */
router.get('/:shop_id', getExpenses);

/**
 * @swagger
 * /expense/{shop_id}/{id}:
 *   get:
 *     summary: Get expense by ID for a specific shop
 *     tags: [Expenses]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Expense details
 */
router.get('/:shop_id/:id', getExpenseById);

/**
 * @swagger
 * /expense/{shop_id}/{id}:
 *   put:
 *     summary: Update expense by ID for a specific shop
 *     tags: [Expenses]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               owner:
 *                 type: string
 *     responses:
 *       200:
 *         description: Expense updated successfully
 */
router.put('/:shop_id/:id', validateRequest(updateExpenseSchema), updateExpense);

/**
 * @swagger
 * /expense/{shop_id}/{id}:
 *   delete:
 *     summary: Delete expense by ID for a specific shop
 *     tags: [Expenses]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Expense deleted successfully
 */
router.delete('/:shop_id/:id', deleteExpense);

module.exports = router;
