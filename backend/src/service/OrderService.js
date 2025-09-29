const Order = require('../models/OrderModel');
const orderItemModel = require('../models/OrderItemModel');
const OrderItemMeasurement = require('../models/OrderItemMeasurementModel');
const OrderItemPattern = require('../models/OrderItemPatternModel');
const Customer = require('../models/CustomerModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { default: mongoose } = require('mongoose');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');

//Order Table Based on Shop
const getOrderModel = (shop_id) => {
  const collectionName = `order_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, Order.schema, collectionName)
  );
};

//Order Item Table Based on Shop
const getOrderItemModel = (shop_id) => {
  const collectionName = `orderItem_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, orderItemModel.schema, collectionName)
  );
};

//Order Measurement Table Based on Shop
const getOrderItemMeasurementModel = (shop_id) => {
  const collectionName = `orderitemmeasurement_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, OrderItemMeasurement.schema, collectionName)
  );
};

//Order Measurement Table Based on Shop
const getOrderItemPatternModel = (shop_id) => {
  const collectionName = `orderitempattern_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, OrderItemPattern.schema, collectionName)
  );
};

const getCustomerModel = (shop_id) => {
  return mongoose.model(`customer_${shop_id}`, Customer.schema);
};

const createOrderService = async (orderData, shop_id) => {
  const session = await Order.startSession();
  session.startTransaction();

  try {
    const { Order: orderDetails, Item } = orderData;

    // Check if Shop Exists
    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    // Initialize models
    const OrderModel = getOrderModel(shop_id);
    const OrderItemModel = getOrderItemModel(shop_id);
    const OrderItemMeasurementModel = getOrderItemMeasurementModel(shop_id);
    const OrderItemPatternModel = getOrderItemPatternModel(shop_id);

    // Generate Order ID
    const orderId = await getNextSequenceValue('orderId');

    // Create Order Document
    const order = new OrderModel({
      orderId,
      ...orderDetails,
      branchId: orderDetails?.branchId,
      customerId: orderDetails?.customerId,
      stitchingType: orderDetails?.stitchingType,
      noOfMeasurementDresses: orderDetails?.noOfMeasurementDresses,
      quantity: orderDetails?.quantity,
      urgent: orderDetails?.urgent,
      status: orderDetails?.status,
      estimationCost: orderDetails?.estimationCost,
      advancereceived: orderDetails?.advancereceived,
      advanceReceivedDate: orderDetails?.advanceReceivedDate,
      gst: orderDetails?.gst,
      courier: orderDetails?.Courier,
      courierCharge: orderDetails?.courierCharge,
      discount: orderDetails?.discount,
      owner: orderDetails?.owner,
    });

    await order.save({ session });

    // Prepare bulk insert arrays
    const orderItems = [];
    const orderItemMeasurements = [];
    const orderItemPatterns = [];

    for (const item of Item) {
      const orderItemId = await getNextSequenceValue('orderItemId');
      const orderItemMeasurementId = await getNextSequenceValue(
        'orderItemMeasurementId'
      );
      const orderItemPatternId =
        await getNextSequenceValue('orderItemPatternId');

      // Order Item
      orderItems.push({
        orderItemId,
        orderId,
        dressTypeId: item?.dressTypeId,
        special_instructions: item?.special_instructions,
        recording: item?.recording,
        videoLink: item?.videoLink,
        Pictures: item?.Pictures,
        deliveryDate: item?.deliveryDate,
        amount: item?.amount,
        status: item?.status,
        owner: item?.owner,
        orderItemMeasurementId,
        orderItemPatternId,
      });

      // Order Item Measurement
      const measurement = {
        orderItemMeasurementId,
        orderId,
        orderItemId,
        customerId: orderDetails?.customerId,
        dressTypeId: item?.dressTypeId,
        owner: item?.owner,
        ...item?.Measurement,
      };
      orderItemMeasurements.push(measurement);

      // Order Item Pattern
      const pattern = {
        orderItemPatternId,
        orderId,
        orderItemId,
        owner: item?.owner,
        patterns: Array.isArray(item?.Pattern)
          ? item?.Pattern?.map((p) => ({
              category: p?.category,
              name: Array.isArray(p?.name) ? p?.name : [p?.name],
            }))
          : [],
      };
      orderItemPatterns.push(pattern);
    }

    // Insert data in bulk
    if (orderItems.length > 0) {
      await OrderItemModel.insertMany(orderItems, { session });
    }

    if (orderItemMeasurements.length > 0) {
      await OrderItemMeasurementModel.insertMany(orderItemMeasurements, {
        session,
      });
    }

    if (orderItemPatterns.length > 0) {
      await OrderItemPatternModel.insertMany(orderItemPatterns, { session });
    }

    // Commit transaction
    await session.commitTransaction();
    session.endSession();

    return { message: 'Order created successfully', order };
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    throw err;
  }
};

const getAllOrdersService = async (shop_id, queryParams) => {
  try {
    if (!shop_id) throw new Error('Shop ID is required');
    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const Order = getOrderModel(shop_id);
    const OrderItem = getOrderItemModel(shop_id);
    const OrderItemMeasurement = getOrderItemMeasurementModel(shop_id);
    const OrderItemPattern = getOrderItemPatternModel(shop_id);
    const Customer = getCustomerModel(shop_id);

    // Query params
    const { orderId } = queryParams;

    const searchableFields = ['customer', 'owner'];
    const numericFields = ['orderId'];
    const options = buildQueryOptions(
      queryParams,
      'createdAt',
      searchableFields,
      numericFields
    );

    // Base query for countDocuments
    const baseQuery = { ...options.search, ...options.booleanFilters };
    if (orderId) baseQuery['orderId'] = Number(orderId);

    console.log('baseQuery', baseQuery);

    // Main aggregation pipeline
    const aggregatePipeline = [
      { $match: baseQuery },
      {
        $lookup: {
          from: Customer.collection.name,
          localField: 'customerId',
          foreignField: 'customerId',
          as: 'customerInfo',
        },
      },
      {
        $unwind: {
          path: '$customerInfo',
          preserveNullAndEmptyArrays: true,
        },
      },

      {
        $addFields: {
          customer_name: '$customerInfo.name',
        },
      },
      {
        $unset: 'customerInfo',
      },
      {
        $lookup: {
          from: OrderItem.collection.name,
          let: { orderId: '$orderId' },
          pipeline: [
            {
              $match: {
                $expr: { $eq: ['$orderId', '$$orderId'] },
              },
            },
            {
              $lookup: {
                from: OrderItemMeasurement.collection.name,
                let: {
                  orderId: '$orderId',
                  orderItemId: '$orderItemId',
                },
                pipeline: [
                  {
                    $match: {
                      $expr: {
                        $and: [
                          { $eq: ['$orderId', '$$orderId'] },
                          { $eq: ['$orderItemId', '$$orderItemId'] },
                        ],
                      },
                    },
                  },
                ],
                as: 'measurement',
              },
            },
            {
              $lookup: {
                from: OrderItemPattern.collection.name,
                let: {
                  orderId: '$orderId',
                  orderItemId: '$orderItemId',
                },
                pipeline: [
                  {
                    $match: {
                      $expr: {
                        $and: [
                          { $eq: ['$orderId', '$$orderId'] },
                          { $eq: ['$orderItemId', '$$orderItemId'] },
                        ],
                      },
                    },
                  },
                ],
                as: 'pattern',
              },
            },
          ],
          as: 'items',
        },
      },
      // Apply sorting and other options
      { $sort: options.sort || { createdAt: -1 } },
    ];

    // Prepare pagination options
    const paginationOptions = {
      aggregate: aggregatePipeline,
      page: options.page || 1,
      limit: options.limit || 10,
      sortBy: options.sort || { createdAt: -1 },
      searchKeyword: options.searchKeyword,
      searchBy: searchableFields,
      select: null,
    };

    const result = await paginate(Order, baseQuery, paginationOptions);
    return result;
  } catch (error) {
    console.error('Error in getAllOrdersService:', error);
    throw error;
  }
};

const updateOrderService = async (orderId, orderData, shop_id) => {
  const session = await Order.startSession();
  session.startTransaction();

  try {
    const { Order: orderDetails, Item } = orderData;

    // Check if shop exists
    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    // Initialize models
    const OrderModel = getOrderModel(shop_id);
    const OrderItemModel = getOrderItemModel(shop_id);
    const OrderItemMeasurementModel = getOrderItemMeasurementModel(shop_id);
    const OrderItemPatternModel = getOrderItemPatternModel(shop_id);

    // Check if order exists
    const existingOrder = await OrderModel.findOne({ orderId });
    if (!existingOrder) throw new Error(`Order with ID ${orderId} not found`);

    // Update the main Order document
    Object.assign(existingOrder, {
      ...orderDetails,
      courier: orderDetails?.Courier, // ensure consistency in field name
    });

    await existingOrder.save({ session });

    // for (const item of Item) {
    //   const orderItemId =
    //     item.orderItemId || (await getNextSequenceValue('orderItemId'));
    //   const orderItemMeasurementId =
    //     item.orderItemMeasurementId ||
    //     (await getNextSequenceValue('orderItemMeasurementId'));
    //   const orderItemPatternId =
    //     item.orderItemPatternId ||
    //     (await getNextSequenceValue('orderItemPatternId'));

    //   // Upsert OrderItem
    //   await OrderItemModel.findOneAndUpdate(
    //     { orderItemId },
    //     {
    //       $set: {
    //         orderId,
    //         dressTypeId: item.dressTypeId,
    //         special_instructions: item.special_instructions,
    //         recording: item.recording,
    //         videoLink: item.videoLink,
    //         Pictures: item.Pictures,
    //         deliveryDate: item.deliveryDate,
    //         amount: item.amount,
    //         status: item.status,
    //         owner: item.owner,
    //         orderItemMeasurementId,
    //         orderItemPatternId,
    //       },
    //     },
    //     { session, upsert: true }
    //   );

    //   // Upsert Measurement
    //   await OrderItemMeasurementModel.findOneAndUpdate(
    //     { orderItemMeasurementId },
    //     {
    //       $set: {
    //         orderId,
    //         orderItemId,
    //         owner: item.owner,
    //         ...item.Measurement,
    //       },
    //     },
    //     { session, upsert: true }
    //   );

    //   // Upsert Pattern
    //   await OrderItemPatternModel.findOneAndUpdate(
    //     { orderItemPatternId },
    //     {
    //       $set: {
    //         orderId,
    //         orderItemId,
    //         owner: item.owner,
    //         patterns: Array.isArray(item?.Pattern)
    //           ? item?.Pattern.map((p) => ({
    //               category: p?.category,
    //               name: Array.isArray(p?.name) ? p?.name : [p?.name],
    //             }))
    //           : [],
    //       },
    //     },
    //     { session, upsert: true }
    //   );
    // }

    for (const item of Item) {
      console.log('item', item);
      // Require IDs for update
      if (
        !item?.orderItemId ||
        !item?.Measurement?.orderItemMeasurementId ||
        !item.Pattern?.map((p) => p?.orderItemPatternId)
      ) {
        throw new Error('Missing IDs for update. Cannot update without IDs.');
      }

      const orderItemId = item.orderItemId;
      const orderItemMeasurementId = item.Measurement.orderItemMeasurementId;
      const orderItemPatternId = item.Pattern[0].orderItemPatternId;

      // const { orderItemId, orderItemMeasurementId, orderItemPatternId } = item;

      // Update Order Item
      await OrderItemModel.updateOne(
        { orderItemId, orderId },
        {
          $set: {
            dressTypeId: item.dressTypeId,
            special_instructions: item.special_instructions,
            recording: item.recording,
            videoLink: item.videoLink,
            Pictures: item.Pictures,
            deliveryDate: item.deliveryDate,
            amount: item.amount,
            status: item.status,
            owner: item.owner,
          },
        },
        { session }
      );

      // Update Measurement
      await OrderItemMeasurementModel.updateOne(
        { orderItemMeasurementId, orderId, orderItemId },
        {
          $set: {
            owner: item.owner,
            ...item.Measurement,
          },
        },
        { session }
      );

      // Update Pattern
      await OrderItemPatternModel.updateOne(
        { orderItemPatternId, orderId, orderItemId },
        {
          $set: {
            owner: item.owner,
            patterns: Array.isArray(item?.Pattern)
              ? item?.Pattern.map((p) => ({
                  category: p?.category,
                  name: Array.isArray(p?.name) ? p?.name : [p?.name],
                }))
              : [],
          },
        },
        { session }
      );
    }

    await session.commitTransaction();
    session.endSession();

    return existingOrder;
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    throw err;
  }
};

module.exports = {
  createOrderService,
  getAllOrdersService,
  updateOrderService,
};
