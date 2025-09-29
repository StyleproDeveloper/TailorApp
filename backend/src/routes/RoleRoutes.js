const express = require('express');
const {
  createRole,
  getRole,
  getRoleById,
  updateRole,
  deleteRole,
} = require('../controller/RoleController');

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Roles
 *   description: Role management APIs
 */

/**
 * @swagger
 * /roles:
 *   post:
 *     summary: Create a new role
 *     tags: [Roles]
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
 *               viewOrder:
 *                 type: boolean
 *               editOrder:
 *                 type: boolean
 *               createOrder:
 *                 type: boolean
 *               viewPrice:
 *                 type: boolean
 *               viewShop:
 *                 type: boolean
 *               editShop:
 *                 type: boolean
 *               viewCustomer:
 *                 type: boolean
 *               editCustomer:
 *                 type: boolean
 *               administration:
 *                 type: boolean
 *               viewReports:
 *                 type: boolean
 *               addDressItem:
 *                 type: boolean
 *               payments:
 *                 type: boolean
 *               viewAllBranches:
 *                 type: boolean
 *               assignDressItem:
 *                 type: boolean
 *               manageOrderStatus:
 *                 type: boolean
 *               manageWorkShop:
 *                 type: boolean
 *               owner:
 *                 type: string
 *                 description: Owner of the role
 *     responses:
 *       201:
 *         description: Role created successfully
 *       500:
 *         description: Server error
 */

/**
 * @swagger
 * /roles:
 *   post:
 *     summary: Create a new role
 *     tags: [Roles]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Role'
 *     responses:
 *       201:
 *         description: Role created successfully
 *       500:
 *         description: Server error
 */
router.post('/', createRole);

/**
 * @swagger
 * /roles/{shop_id}:
 *   get:
 *     summary: Get all roles with pagination, sorting, and searching
 *     tags: [Roles]
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
 *         description: Paginated list of roles
 *       500:
 *         description: Server error
 */
router.get('/:shop_id', getRole);

/**
 * @swagger
 * /roles/{shop_id}/{id}:
 *   get:
 *     summary: Get a role by ID
 *     tags: [Roles]
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
 *         description: Role details
 *       404:
 *         description: Role not found
 *       500:
 *         description: Server error
 */
router.get('/:shop_id/:id', getRoleById);

/**
 * @swagger
 * /roles/{shop_id}/{id}:
 *   put:
 *     summary: Update a role
 *     tags: [Roles]
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
 *             properties:
 *               name:
 *                 type: string
 *               viewOrder:
 *                 type: boolean
 *               editOrder:
 *                 type: boolean
 *               createOrder:
 *                 type: boolean
 *               viewPrice:
 *                 type: boolean
 *               viewShop:
 *                 type: boolean
 *               editShop:
 *                 type: boolean
 *               viewCustomer:
 *                 type: boolean
 *               editCustomer:
 *                 type: boolean
 *               administration:
 *                 type: boolean
 *               viewReports:
 *                 type: boolean
 *               addDressItem:
 *                 type: boolean
 *               payments:
 *                 type: boolean
 *               viewAllBranches:
 *                 type: boolean
 *               assignDressItem:
 *                 type: boolean
 *               manageOrderStatus:
 *                 type: boolean
 *               manageWorkShop:
 *                 type: boolean
 *               owner:
 *                 type: string
 *     responses:
 *       200:
 *         description: Role updated successfully
 *       404:
 *         description: Role not found
 *       500:
 *         description: Server error
 */
router.put('/:shop_id/:id', updateRole);

/**
 * @swagger
 * /roles/{shop_id}/{id}:
 *   delete:
 *     summary: Delete a role
 *     tags: [Roles]
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
 *         description: Role deleted successfully
 *       404:
 *         description: Role not found
 *       500:
 *         description: Server error
 */
router.delete('/:shop_id/:id', deleteRole);

module.exports = router;
