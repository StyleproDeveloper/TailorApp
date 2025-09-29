const express = require('express');
const router = express.Router();
const {
  createDressTypeMeasurement,
  getDressTypeMeasurements,
  getDressTypeMeasurementById,
  updateDressTypeMeasurement,
  deleteDressTypeMeasurement,
} = require('../controller/DressTypeMeasurementController');
const dressTypeMeasurementValidationSchema = require('../validations/DressTypeMeasurementValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @swagger
 * tags:
 *   name: DressTypeMeasurement
 *   description: DressTypeMeasurement APIs
 */

/**
 * @swagger
 * /dresstype-measurement:
 *   post:
 *     summary: Create a new dresstype-measurement
 *     tags: [DressTypeMeasurement]
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
 *                 name:
 *                   type: string
 *                 measurementId:
 *                   type: number
 *                 owner:
 *                   type: string
 *     responses:
 *       201:
 *         description: DressTypeMeasurement created successfully
 */
router.post(
  '/',
  validateRequest(dressTypeMeasurementValidationSchema),
  createDressTypeMeasurement
);

/**
 * @swagger
 * /dresstype-measurement/{shop_id}:
 *   get:
 *     summary: Get all dresstypeMeasurements for a specific shop
 *     tags: [DressTypeMeasurement]
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
 *         description: List of dresstypeMeasurements
 */
router.get('/:shop_id', getDressTypeMeasurements);

/**
 * @swagger
 * /dresstype-measurement/{shop_id}/{id}:
 *   get:
 *     summary: Get dresstype-measurement by ID for a specific shop
 *     tags: [DressTypeMeasurement]
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
 *         description: DressTypeMeasurement details
 */
router.get('/:shop_id/:id', getDressTypeMeasurementById);

/**
 * @swagger
 * /dresstype-measurement:
 *   put:
 *     summary: Bulk update Dress Type Measurements
 *     tags: [DressTypeMeasurement]
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
 *                 - dressTypeMeasurementId
 *               properties:
 *                 shop_id:
 *                   type: number
 *                 dressTypeMeasurementId:
 *                   type: number
 *                 dressTypeId:
 *                   type: number
 *                 name:
 *                   type: string
 *                 measurementId:
 *                   type: number
 *                 owner:
 *                   type: string
 *     responses:
 *       200:
 *         description: Updated successfully
 */
router.put(
  '/',
  validateRequest(dressTypeMeasurementValidationSchema),
  updateDressTypeMeasurement
);

/**
 * @swagger
 * /dresstype-measurement/{shop_id}/{id}:
 *   delete:
 *     summary: Delete dresstype-measurement by ID for a specific shop
 *     tags: [DressTypeMeasurement]
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
 *         description: DressTypeMeasurement deleted successfully
 */
router.delete('/:shop_id/:id', deleteDressTypeMeasurement);

module.exports = router;
