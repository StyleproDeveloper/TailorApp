const express = require('express');
const {
  createCustomer,
  getCustomer,
  getCustomerById,
  updateCustomer,
  deleteCustomer,
  getCustomerMeasurement,
} = require('../controller/CustomerController');

const router = express.Router();

const customerValidationSchema = require('../validations/CustomerValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @swagger
 * tags:
 *   name: Customers
 *   description: Customer management APIs
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Customer:
 *       type: object
 *       required:
 *         - name
 *         - gender
 *         - mobile
 *       properties:
 *         shop_id:
 *           type: number
 *         name:
 *           type: string
 *         gender:
 *           type: string
 *           enum: [male, feMale, other]
 *         mobile:
 *           type: string
 *         secondaryMobile:
 *           type: string
 *         email:
 *           type: string
 *         dateOfBirth:
 *           type: string
 *           format: date
 *         addressLine1:
 *           type: string
 *         remark:
 *           type: string
 *         notificationOptIn:
 *           type: boolean
 *         owner:
 *           type: string
 *         branch_id:
 *           type: string
 */

/**
 * @swagger
 * /customer:
 *   post:
 *     summary: Create a new customer
 *     tags: [Customers]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Customer'
 *     responses:
 *       201:
 *         description: Customer created successfully
 */
router.post('/', validateRequest(customerValidationSchema), createCustomer);

/**
 * @swagger
 * /customer/{shop_id}:
 *   get:
 *     summary: Retrieve a list of customers for a specific shop
 *     tags: [Customers]
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
 *         description: A list of customers
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 total:
 *                   type: integer
 *                   description: Total number of customers
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Customer'
 */
router.get('/:shop_id', getCustomer);

/**
 * @swagger
 * /customer/{shop_id}/{id}:
 *   get:
 *     summary: Get a customer by ID
 *     tags: [Customers]
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
 *         description: Customer retrieved successfully
 */
router.get('/:shop_id/:id', getCustomerById);

/**
 * @swagger
 * /customer/measurements/{shop_id}/{customerId}:
 *   get:
 *     summary: Get measurement details for a customer
 *     tags: [Customers]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *         schema:
 *           type: string
 *         description: Shop ID
 *       - in: path
 *         name: customerId
 *         required: true
 *         schema:
 *           type: integer
 *         description: Customer ID
 *     responses:
 *       200:
 *         description: Customer measurements with dress type details
 *       500:
 *         description: Server error
 */
router.get('/measurements/:shop_id/:customerId', getCustomerMeasurement);

/**
 * @swagger
 * /customer/{shop_id}/{id}:
 *   put:
 *     summary: Update a customer
 *     tags: [Customers]
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
 *             $ref: '#/components/schemas/Customer'
 *     responses:
 *       200:
 *         description: Customer updated successfully
 */
router.put(
  '/:shop_id/:id',
  validateRequest(customerValidationSchema),
  updateCustomer
);

/**
 * @swagger
 * /customer/{shop_id}/{id}:
 *   delete:
 *     summary: Delete a customer
 *     tags: [Customers]
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
 *         description: Customer deleted successfully
 */
router.delete('/:shop_id/:id', deleteCustomer);

module.exports = router;
