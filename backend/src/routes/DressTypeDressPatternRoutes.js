const express = require('express');
const router = express.Router();
const {
  createDressTypeDressPattern,
  getDressTypeDressPattern,
  getDressTypeDressPatternById,
  updateDressTypeDressPattern,
  deleteDressTypeDressPattern,
} = require('../controller/DressTypeDressPatternController');
const DressTypeDressPatternValidationSchema = require('../validations/DressTypeDressPatternValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @swagger
 * /dress-type-pattern:
 *   post:
 *     summary: Create multiple DressTypeDressPattern records
 *     tags: [Dress Type Dress Patterns]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: array
 *             items:
 *               type: object
 *               properties:
 *                 shop_id:
 *                   type: number
 *                 dressTypeId:
 *                   type: number
 *                 category:
 *                   type: string
 *                 dressPatternId:
 *                   type: number
 *                 owner:
 *                   type: string
 *     responses:
 *       201:
 *         description: DressTypeDressPatterns created successfully
 */
router.post(
  '/',
  validateRequest(DressTypeDressPatternValidationSchema),
  createDressTypeDressPattern
);

/**
 * @swagger
 * /dress-type-pattern/{shop_id}:
 *   get:
 *     summary: Get all Dress Type Dress Patterns
 *     tags: [Dress Type Dress Patterns]
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
 *         description: List of Dress Type Dress Patterns
 */
router.get('/:shop_id', getDressTypeDressPattern);

/**
 * @swagger
 * /dress-type-pattern/{shop_id}/{id}:
 *   get:
 *     summary: Get dress-type-pattern by ID
 *     tags: [Dress Type Dress Patterns]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: DressTypeDressPattern details
 */
router.get('/:shop_id/:id', getDressTypeDressPatternById);

/**
 * @swagger
 * /dress-type-pattern:
 *   put:
 *     summary: Update multiple dress-type-pattern records
 *     tags: [Dress Type Dress Patterns]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: array
 *             items:
 *               type: object
 *               required:
 *                 - shop_id
 *                 - dressTypePatternId
 *               properties:
 *                 shop_id:
 *                   type: number
 *                 dressTypePatternId:
 *                   type: number
 *                 dressTypeId:
 *                   type: number
 *                 category:
 *                   type: string
 *                 dressPatternId:
 *                   type: number
 *     responses:
 *       200:
 *         description: Dress Type Dress Patterns updated successfully
 */
router.put(
  '/',
  validateRequest(DressTypeDressPatternValidationSchema), // You can also create a new schema for update
  updateDressTypeDressPattern
);

/**
 * @swagger
 * /dress-type-pattern/{shop_id}/{id}:
 *   delete:
 *     summary: Delete dress-type-pattern by ID
 *     tags: [Dress Type Dress Patterns]
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
 *         description: DressTypeDressPattern deleted successfully
 */
router.delete('/:shop_id/:id', deleteDressTypeDressPattern);

module.exports = router;
