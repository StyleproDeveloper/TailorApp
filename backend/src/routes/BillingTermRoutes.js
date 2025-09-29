const express = require('express');
const router = express.Router();
const {
  createBillingTerm,
  getBillingTerm,
  getBillingTermById,
  updateBillingTerm,
  deleteBillingTerm,
} = require('../controller/BillingTermController');

/**
 * @swagger
 * tags:
 *   name: Billing Terms
 *   description: Billing Terms APIs
 */

/**
 * @swagger
 * /billing-term:
 *   post:
 *     summary: Create a new billing-term
 *     tags: [Billing Terms]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               shop_id:
 *                 type: number
 *               terms:
 *                 type: string
 *               gst_no:
 *                 type: string
 *               gst_reg_date:
 *                 type: string
 *                 example: "2025-03-30"
 *               gst_state:
 *                 type: string
 *               gst_address:
 *                 type: string
 *               gst_available:
 *                 type: boolean
 *               owner:
 *                 type: string
 *     responses:
 *       201:
 *         description: Billing Terms created successfully
 */
router.post('/', createBillingTerm);

/**
 * @swagger
 * /billing-term/{shop_id}:
 *   get:
 *     summary: Get all billingTerms for a specific shop
 *     tags: [Billing Terms]
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
 *         description: List of billingTerms
 */
router.get('/:shop_id', getBillingTerm);

/**
 * @swagger
 * /billing-term/{shop_id}/{id}:
 *   get:
 *     summary: Get billing-term by ID for a specific shop
 *     tags: [Billing Terms]
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
 *         description: Billing Terms details
 */
router.get('/:shop_id/:id', getBillingTermById);

/**
 * @swagger
 * /billing-term/{shop_id}/{id}:
 *   put:
 *     summary: Update billing-term by ID for a specific shop
 *     tags: [Billing Terms]
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
 *               terms:
 *                 type: string
 *               gst_no:
 *                 type: string
 *               gst_reg_date:
 *                 type: Date
 *               gst_state:
 *                 type: string
 *               gst_address:
 *                 type: string
 *               gst_available:
 *                 type: boolean
 *               owner:
 *                 type: string
 *     responses:
 *       200:
 *         description: Billing Terms updated successfully
 */
router.put('/:shop_id/:id', updateBillingTerm);

/**
 * @swagger
 * /billing-term/{shop_id}/{id}:
 *   delete:
 *     summary: Delete billing-term by ID for a specific shop
 *     tags: [Billing Terms]
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
 *         description: Billing Terms deleted successfully
 */
router.delete('/:shop_id/:id', deleteBillingTerm);

module.exports = router;
