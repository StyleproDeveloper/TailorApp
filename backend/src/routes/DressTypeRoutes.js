const express = require('express');
const router = express.Router();
const {
  createDressType,
  getDressType,
  getDressTypeById,
  updateDressType,
  deleteDressType,
} = require('../controller/DressTypeController');
const dressTypeSchema = require('../validations/DressTypeValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @swagger
 * /dress-type:
 *   post:
 *     summary: Create a new DressType
 *     tags: [DressTypes]
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
 *         description: DressType created successfully
 */
router.post('/', validateRequest(dressTypeSchema), createDressType);

/**
 * @swagger
 * /dress-type/{shop_id}:
 *   get:
 *     summary: Get all DressTypes
 *     tags: [DressTypes]
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
 *         description: List of DressTypes
 */
router.get('/:shop_id', getDressType);

/**
 * @swagger
 * /dress-type/{shop_id}/{id}:
 *   get:
 *     summary: Get dress-type by ID
 *     tags: [DressTypes]
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
 *         description: DressType details
 */
router.get('/:shop_id/:id', getDressTypeById);

/**
 * @swagger
 * /dress-type/{shop_id}/{id}:
 *   put:
 *     summary: Update dress-type by ID
 *     tags: [DressTypes]
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
 *               name:
 *                 type: string
 *               owner:
 *                 type: string
 *     responses:
 *       200:
 *         description: DressType updated successfully
 */
router.put('/:shop_id/:id', validateRequest(dressTypeSchema), updateDressType);

/**
 * @swagger
 * /dress-type/{shop_id}/{id}:
 *   delete:
 *     summary: Delete dress-type by ID
 *     tags: [DressTypes]
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
 *         description: DressType deleted successfully
 */
router.delete('/:shop_id/:id', deleteDressType);

module.exports = router;
