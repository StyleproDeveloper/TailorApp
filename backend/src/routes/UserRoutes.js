const express = require('express');
const router = express.Router();
const {
  CreateUser,
  getUser,
  getUserById,
  updateUser,
  deleteUser,
} = require('../controller/UserController');
const validateRequest = require('../middlewares/validateRequest');
const userSchema = require('../validations/UserValidation');

/**
 * @swagger
 * tags:
 *   name: Users
 *   description: User management APIs
 */

/**
 * @swagger
 * /users:
 *   post:
 *     summary: Create a new user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               shopId:
 *                 type: number
 *               branchId:
 *                 type: number
 *               mobile:
 *                 type: string
 *               name:
 *                 type: string
 *               roleId:
 *                 type: number
 *               secondaryMobile:
 *                 type: string
 *               email:
 *                 type: string
 *               addressLine1:
 *                 type: string
 *               street:
 *                 type: string
 *               city:
 *                 type: string
 *               postalCode:
 *                 type: number
 *     responses:
 *       201:
 *         description: User created successfully
 */
router.post('/', validateRequest(userSchema), CreateUser);

/**
 * @swagger
 * /users:
 *   get:
 *     summary: Get all users
 *     tags: [Users]
 *     parameters:
 *       - in: path
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
 *         description: List of users
 */
router.get('/', getUser);

/**
 * @swagger
 * /users/{id}:
 *   get:
 *     summary: Get user by ID
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: User details
 */
router.get('/:id', getUserById);

/**
 * @swagger
 * /users/{id}:
 *   put:
 *     summary: Update user by ID
 *     tags: [Users]
 *     parameters:
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
 *               shopId:
 *                 type: number
 *               branchId:
 *                 type: number
 *               mobile:
 *                 type: string
 *               name:
 *                 type: string
 *               roleId:
 *                 type: number
 *               secondaryMobile:
 *                 type: string
 *               email:
 *                 type: string
 *               addressLine1:
 *                 type: string
 *               street:
 *                 type: string
 *               city:
 *                 type: string
 *               postalCode:
 *                 type: number
 *     responses:
 *       200:
 *         description: User updated successfully
 */
router.put('/:id', validateRequest(userSchema), updateUser);

/**
 * @swagger
 * /users/{id}:
 *   delete:
 *     summary: Delete user by ID
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: User deleted successfully
 */
router.delete('/:id', deleteUser);

module.exports = router;
