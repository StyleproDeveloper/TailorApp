const express = require('express');
const {
  createShop,
  getShops,
  getShopById,
  updateShop,
  deleteShop,
} = require('../controller/ShopController');
const router = express.Router();
const ShopValidationSchema = require('../validations/ShopValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @swagger
 * components:
 *   schemas:
 *     Shop:
 *       type: object
 *       required:
 *         - branch_id
 *         - yourName
 *         - mobile
 *       properties:
 *         branch_id:
 *           type: number
 *         yourName:
 *           type: string
 *         shopName:
 *           type: string
 *         code:
 *           type: string
 *         shopType:
 *           type: string
 *         mobile:
 *           type: string
 *         secondaryMobile:
 *           type: string
 *         email:
 *           type: string
 *         website:
 *           type: string
 *         instagram_url:
 *           type: string
 *         facebook_url:
 *           type: string
 *         addressLine1:
 *           type: string
 *         street:
 *           type: string
 *         city:
 *           type: string
 *         state:
 *           type: string
 *         postalCode:
 *           type: number
 *         subscriptionType:
 *           type: number
 *         subscriptionEndDate:
 *           type: string
 *         setupComplete:
 *           type: boolean
 */

/**
 * @swagger
 * /shops:
 *   post:
 *     summary: Create a new shop
 *     tags: [Shop]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Shop'
 *     responses:
 *       201:
 *         description: Shop created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shop'
 *       500:
 *         description: Server error
 */
router.post('/', validateRequest(ShopValidationSchema), createShop);

/**
 * @swagger
 * /shops:
 *   get:
 *     summary: Retrieve a list of shops
 *     tags: [Shop]
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
 *         description: A list of shops
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Shop'
 *       500:
 *         description: Server error
 */

router.get('/', getShops);
/**
 * @swagger
 * /shops/{id}:
 *   get:
 *     summary: Get a shop by ID
 *     tags: [Shop]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: The shop ID
 *     responses:
 *       200:
 *         description: The shop data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shop'
 *       404:
 *         description: Shop not found
 *       500:
 *         description: Server error
 */

router.get('/:id', getShopById);

/**
 * @swagger
 * /shops/{id}:
 *   put:
 *     summary: Update a shop
 *     tags: [Shop]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: The shop ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Shop'
 *     responses:
 *       200:
 *         description: Shop updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shop'
 *       404:
 *         description: Shop not found
 *       500:
 *         description: Server error
 */

router.put('/:id', validateRequest(ShopValidationSchema), updateShop);

/**
 * @swagger
 * /shops/{id}:
 *   delete:
 *     summary: Delete a shop
 *     tags: [Shop]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: The shop ID
 *     responses:
 *       200:
 *         description: Shop deleted successfully
 *       404:
 *         description: Shop not found
 *       500:
 *         description: Server error
 */
router.delete('/:id', deleteShop);

module.exports = router;
