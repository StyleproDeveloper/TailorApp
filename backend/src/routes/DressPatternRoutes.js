const express = require('express');
const {
  createDressPattern,
  getDRessPattern,
  getDRessPatternById,
  updateDresssPattern,
  deleteDressPattern,
} = require('../controller/DressPatternController');

const router = express.Router();

const dressPatternValidationSchema = require('../validations/DressPatternValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @swagger
 * tags:
 *   name: Dress Pattern
 *   description: DressPattern management APIs
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     DressPattern:
 *       type: object
 *       required:
 *         - name
 *         - category
 *       properties:
 *         shop_id:
 *           type: number
 *         name:
 *           type: string
 *         category:
 *           type: string
 *         owner:
 *           type: string
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     DressPatternUpdate:
 *       type: object
 *       required:
 *         - name
 *         - category
 *       properties:
 *         name:
 *           type: string
 *         category:
 *           type: string
 *         owner:
 *           type: string
 */

/**
 * @swagger
 * /dress-pattern:
 *   post:
 *     summary: Create a new dress-pattern
 *     tags: [Dress Pattern]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/DressPattern'
 *     responses:
 *       201:
 *         description: DressPattern created successfully
 */
router.post(
  '/',
  validateRequest(dressPatternValidationSchema),
  createDressPattern
);

/**
 * @swagger
 * /dress-pattern/{shop_id}:
 *   get:
 *     summary: Retrieve a list of dressPatterns for a specific shop
 *     tags: [Dress Pattern]
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
 *         description: A list of dressPatterns
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 total:
 *                   type: integer
 *                   description: Total number of dressPatterns
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/DressPattern'
 */
router.get('/:shop_id', getDRessPattern);

/**
 * @swagger
 * /dress-pattern/{shop_id}/{id}:
 *   get:
 *     summary: Get a dress-pattern by ID
 *     tags: [Dress Pattern]
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
 *         description: DressPattern retrieved successfully
 */
router.get('/:shop_id/:id', getDRessPatternById);

/**
 * @swagger
 * /dress-pattern/{shop_id}/{id}:
 *   put:
 *     summary: Update a dress-pattern
 *     tags: [Dress Pattern]
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
 *             $ref: '#/components/schemas/DressPatternUpdate'
 *     responses:
 *       200:
 *         description: DressPattern updated successfully
 */
router.put(
  '/:shop_id/:id',
  validateRequest(dressPatternValidationSchema),
  updateDresssPattern
);

/**
 * @swagger
 * /dress-pattern/{shop_id}/{id}:
 *   delete:
 *     summary: Delete a dress-pattern
 *     tags: [Dress Pattern]
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
 *         description: DressPattern deleted successfully
 */
router.delete('/:shop_id/:id', deleteDressPattern);

module.exports = router;
