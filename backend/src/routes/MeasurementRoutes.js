const express = require('express');
const router = express.Router();
const {
  createMeasurement,
  getMeasurement,
  getMeasurementById,
  updateMeasurement,
  deleteMeasurement,
} = require('../controller/MeasurementController');

/**
 * @swagger
 * tags:
 *   name: Measurements
 *   description: Measurement APIs
 */

/**
 * @swagger
 * /measurement:
 *   post:
 *     summary: Create a new measurement for a specific shop
 *     tags: [Measurements]
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
 *         description: Measurement created successfully
 */
router.post('/', createMeasurement);

/**
 * @swagger
 * /measurement/{shop_id}:
 *   get:
 *     summary: Get all measurement for a specific shop
 *     tags: [Measurements]
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
 *         description: List of measurement
 */
router.get('/:shop_id', getMeasurement);

/**
 * @swagger
 * /measurement/{shop_id}/{id}:
 *   get:
 *     summary: Get measurement by ID for a specific shop
 *     tags: [Measurements]
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
 *         description: Measurement details
 */
router.get('/:shop_id/:id', getMeasurementById);

/**
 * @swagger
 * /measurement/{shop_id}/{id}:
 *   put:
 *     summary: Update measurement by ID for a specific shop
 *     tags: [Measurements]
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
 *         description: Measurement updated successfully
 */
router.put('/:shop_id/:id', updateMeasurement);

/**
 * @swagger
 * /measurement/{shop_id}/{id}:
 *   delete:
 *     summary: Delete measurement by ID for a specific shop
 *     tags: [Measurements]
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
 *         description: Measurement deleted successfully
 */
router.delete('/:shop_id/:id', deleteMeasurement);

module.exports = router;
