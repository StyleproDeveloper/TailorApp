const express = require('express');
const router = express.Router();
const {
  createUserBranch,
  getUserBranch,
  getUserBranchId,
  updateUserBranch,
  deleteUserBranch,
} = require('../controller/UserBarnchController');

/**
 * @swagger
 * tags:
 *   name: User Branches
 *   description: User Branch APIs
 */

/**
 * @swagger
 * /user-branch:
 *   post:
 *     summary: Create a new user-branch
 *     tags: [User Branches]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               shop_id:
 *                 type: number
 *               userId:
 *                 type: number
 *               branchId:
 *                 type: number
 *               owner:
 *                 type: string
 *     responses:
 *       201:
 *         description: User Branch created successfully
 */
router.post('/', createUserBranch);

/**
 * @swagger
 * /user-branch/{shop_id}:
 *   get:
 *     summary: Get all userBranchs for a specific shop
 *     tags: [User Branches]
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
 *         description: List of userBranchs
 */
router.get('/:shop_id', getUserBranch);

/**
 * @swagger
 * /user-branch/{shop_id}/{id}:
 *   get:
 *     summary: Get user-branch by ID for a specific shop
 *     tags: [User Branches]
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
 *         description: User Branch details
 */
router.get('/:shop_id/:id', getUserBranchId);

/**
 * @swagger
 * /user-branch/{shop_id}/{id}:
 *   put:
 *     summary: Update user-branch by ID for a specific shop
 *     tags: [User Branches]
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
 *               userId:
 *                 type: number
 *               branchId:
 *                 type: number
 *               owner:
 *                 type: string
 *     responses:
 *       200:
 *         description: User Branch updated successfully
 */
router.put('/:shop_id/:id', updateUserBranch);

/**
 * @swagger
 * /user-branch/{shop_id}/{id}:
 *   delete:
 *     summary: Delete user-branch by ID for a specific shop
 *     tags: [User Branches]
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
 *         description: User Branch deleted successfully
 */
router.delete('/:shop_id/:id', deleteUserBranch);

module.exports = router;
