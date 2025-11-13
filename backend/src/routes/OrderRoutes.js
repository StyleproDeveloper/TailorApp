const express = require('express');
const router = express.Router();
const {
  createOrder,
  getAllOrders,
  updateOrder,
  updateOrderItemDeliveryStatus,
} = require('../controller/OrderController');
const createOrderPayloadSchema = require('../validations/OrderValidation');
const validateRequest = require('../middlewares/validateRequest');

/**
 * @swagger
 * /orders:
 *   post:
 *     summary: Create a new order
 *     description: Create a new order with multiple items, measurements, and patterns.
 *     tags:
 *       - Orders
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               Order:
 *                 type: object
 *                 properties:
 *                   shop_id:
 *                     type: number
 *                   branchId:
 *                     type: number
 *                   customerId:
 *                     type: number
 *                   stitchingType:
 *                     type: number
 *                   noOfMeasurementDresses:
 *                     type: number
 *                   quantity:
 *                     type: number
 *                   urgent:
 *                     type: boolean
 *                   status:
 *                     type: string
 *                   estimationCost:
 *                     type: number
 *                   advancereceived:
 *                     type: number
 *                   advanceReceivedDate:
 *                     type: string
 *                     format: date
 *                     example: 2025-04-09
 *                   gst:
 *                     type: boolean
 *                   gst_amount:
 *                     type: number
 *                   Courier:
 *                     type: boolean
 *                   courierCharge:
 *                     type: number
 *                   discount:
 *                     type: number
 *                   owner:
 *                     type: string
 *               Item:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     dressTypeId:
 *                       type: number
 *                     Measurement:
 *                       type: object
 *                       properties:
 *                         length:
 *                           type: number
 *                         shoulder_width:
 *                           type: number
 *                         bust:
 *                          type: number
 *                         above_bust:
 *                           type: number
 *                         below_bust:
 *                           type: number
 *                         waist:
 *                           type: number
 *                         ankle_circumference:
 *                           type: number
 *                         hip_circumference:
 *                           type: number
 *                         sleeve_length:
 *                           type: number
 *                         arm_hole:
 *                           type: number
 *                         bicef_circumference:
 *                           type: number
 *                         elbow_circumference:
 *                           type: number
 *                         wrist_circumference:
 *                           type: number
 *                         front_neck_depth:
 *                           type: number
 *                         back_neck_depth:
 *                           type: number
 *                         thigh_circumference:
 *                           type: number
 *                         fly:
 *                           type: number
 *                         inseam:
 *                           type: number
 *                         crotch:
 *                           type: number
 *                         upper_front:
 *                           type: number
 *                         mid_front:
 *                           type: number
 *                         lower_front:
 *                           type: number
 *                     Pattern:
 *                       type: array
 *                       description: List of pattern categories with their respective pattern names
 *                       items:
 *                         type: object
 *                         properties:
 *                           category:
 *                             type: string
 *                           name:
 *                             type: array
 *                             items:
 *                               type: string
 *                     special_instructions:
 *                       type: string
 *                     recording:
 *                       type: string
 *                     pictures:
 *                       type: array
 *                       items:
 *                         type: string
 *                     delivery_date:
 *                       type: string
 *                       format: date
 *                       example: 2025-04-09
 *                     amount:
 *                       type: number
 *                     status:
 *                       type: string
 *                     owner:
 *                       type: string
 *     responses:
 *       201:
 *         description: Order created successfully
 *       500:
 *         description: Server error
 */
router.post('/', validateRequest(createOrderPayloadSchema), createOrder);

/**
 * @swagger
 * /orders/{shop_id}:
 *   get:
 *     summary: Get all orders with items, measurements, and patterns
 *     tags: [Orders]
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
 *       - in: query
 *         name: orderId
 *         schema:
 *           type: string
 *         description: Filter by Order ID
 *       - in: query
 *         name: orderItemId
 *         schema:
 *           type: string
 *         description: Filter by Order Item ID
 *       - in: query
 *         name: orderMeasurementId
 *         schema:
 *           type: string
 *         description: Filter by Order Item Measurement ID
 *       - in: query
 *         name: orderPatternId
 *         schema:
 *           type: string
 *         description: Filter by Order Item Pattern ID
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *         description: Filter by order status (received, in-progress, completed, delivered)
 *         example: in-progress
 *     responses:
 *       200:
 *         description: List of orders
 */
router.get('/:shop_id', getAllOrders);

/**
 * @swagger
 * /orders/{shop_id}/{id}:
 *   put:
 *     summary: Update a new order
 *     description: Update a new order with multiple items, measurements, and patterns.
 *     tags:
 *       - Orders
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
 *               Order:
 *                 type: object
 *                 properties:
 *                   shop_id:
 *                     type: number
 *                   branchId:
 *                     type: number
 *                   customerId:
 *                     type: number
 *                   stitchingType:
 *                     type: number
 *                   noOfMeasurementDresses:
 *                     type: number
 *                   quantity:
 *                     type: number
 *                   urgent:
 *                     type: boolean
 *                   status:
 *                     type: string
 *                   estimationCost:
 *                     type: number
 *                   advancereceived:
 *                     type: number
 *                   advanceReceivedDate:
 *                     type: string
 *                     format: date
 *                     example: 2025-04-09
 *                   gst:
 *                     type: boolean
 *                   gst_amount:
 *                     type: number
 *                   Courier:
 *                     type: boolean
 *                   courierCharge:
 *                     type: number
 *                   discount:
 *                     type: number
 *                   owner:
 *                     type: string
 *               Item:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     orderItemId:
 *                       type: number
 *                     dressTypeId:
 *                       type: number
 *                     Measurement:
 *                       type: object
 *                       properties:
 *                         orderItemMeasurementId:
 *                           type: number
 *                         length:
 *                           type: number
 *                         shoulder_width:
 *                           type: number
 *                         bust:
 *                           type: number
 *                         above_bust:
 *                           type: number
 *                         below_bust:
 *                           type: number
 *                         waist:
 *                           type: number
 *                         ankle_circumference:
 *                           type: number
 *                         hip_circumference:
 *                           type: number
 *                         sleeve_length:
 *                           type: number
 *                         arm_hole:
 *                           type: number
 *                         bicef_circumference:
 *                           type: number
 *                         elbow_circumference:
 *                           type: number
 *                         wrist_circumference:
 *                           type: number
 *                         front_neck_depth:
 *                           type: number
 *                         back_neck_depth:
 *                           type: number
 *                         thigh_circumference:
 *                           type: number
 *                         fly:
 *                           type: number
 *                         inseam:
 *                           type: number
 *                         crotch:
 *                           type: number
 *                         upper_front:
 *                           type: number
 *                         mid_front:
 *                           type: number
 *                         lower_front:
 *                           type: number
 *                     Pattern:
 *                       type: array
 *                       description: List of pattern categories with their respective pattern names
 *                       items:
 *                         type: object
 *                         properties:
 *                           orderItemPatternId:
 *                             type: number
 *                           category:
 *                             type: string
 *                           name:
 *                             type: array
 *                             items:
 *                               type: string
 *                     special_instructions:
 *                       type: string
 *                     recording:
 *                       type: string
 *                     pictures:
 *                       type: array
 *                       items:
 *                         type: string
 *                     delivery_date:
 *                       type: string
 *                       format: date
 *                       example: 2025-04-09
 *                     amount:
 *                       type: number
 *                     status:
 *                       type: string
 *                     owner:
 *                       type: string
 *     responses:
 *       201:
 *         description: Order created successfully
 *       500:
 *         description: Server error
 */
router.put(
  '/:shop_id/:id',
  validateRequest(createOrderPayloadSchema),
  updateOrder
);

/**
 * @swagger
 * /orders/{shop_id}/item/{orderItemId}/delivery:
 *   patch:
 *     summary: Update order item delivery status
 *     tags: [Orders]
 *     parameters:
 *       - in: path
 *         name: shop_id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: orderItemId
 *         required: true
 *         schema:
 *           type: number
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               delivered:
 *                 type: boolean
 *               actualDeliveryDate:
 *                 type: string
 *                 format: date
 *     responses:
 *       200:
 *         description: Order item delivery status updated successfully
 *       404:
 *         description: Order item not found
 */
router.patch('/:shop_id/item/:orderItemId/delivery', updateOrderItemDeliveryStatus);

module.exports = router;
