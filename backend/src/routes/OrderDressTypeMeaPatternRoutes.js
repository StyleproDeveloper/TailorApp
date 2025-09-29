const express = require('express');
const router = express.Router();
const {
  getOrderDressTypeMeaPattern,
} = require('../controller/OrderDressTypeMeaPatternController');

/**
 * @swagger
 * /order-dressType-mea/{shop_id}/{dressTypeId}:
 *   get:
 *     summary: Get all Order Dress Type Measurements and Patterns
 *     tags: [Order DressType Measurement and Patterns]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: dressTypeId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Dress Type Details with Measurements and Patterns
 */
router.get('/:shop_id/:dressTypeId', getOrderDressTypeMeaPattern);

module.exports = router;
