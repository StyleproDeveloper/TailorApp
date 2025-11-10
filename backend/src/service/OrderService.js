const Order = require('../models/OrderModel');
const orderItemModel = require('../models/OrderItemModel');
const OrderItemMeasurement = require('../models/OrderItemMeasurementModel');
const OrderItemPattern = require('../models/OrderItemPatternModel');
const OrderItemAdditionalCost = require('../models/OrderItemAdditionalCostModel');
const Customer = require('../models/CustomerModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { default: mongoose } = require('mongoose');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');
const logger = require('../utils/logger');

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

//Order Item Additional Cost Table Based on Shop
const getOrderItemAdditionalCostModel = (shop_id) => {
  const collectionName = `orderitemadditionalcost_${shop_id}`;
  return (
    mongoose.models[collectionName] ||
    mongoose.model(collectionName, OrderItemAdditionalCost.schema, collectionName)
  );
};

const createOrderService = async (orderData, shop_id) => {
  const session = await Order.startSession();
  session.startTransaction();

  try {
    const { Order: orderDetails, Item, AdditionalCosts } = orderData || {};

    // Check if Shop Exists
    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    // Initialize models
    const OrderModel = getOrderModel(shop_id);
    const OrderItemModel = getOrderItemModel(shop_id);
    const OrderItemMeasurementModel = getOrderItemMeasurementModel(shop_id);
    const OrderItemPatternModel = getOrderItemPatternModel(shop_id);
    const OrderItemAdditionalCostModel = getOrderItemAdditionalCostModel(shop_id);

    // Generate Order ID - shop-specific (and branch-specific if branchId exists)
    const branchId = orderDetails?.branchId || null;
    const orderId = await getNextSequenceValue('orderId', shop_id, branchId);

    // Calculate earliest delivery date from all items
    let earliestDeliveryDate = null;
    if (Item && Item.length > 0) {
      const deliveryDates = Item
        .map(item => item?.delivery_date)
        .filter(date => date && date.trim() !== '')
        .sort(); // Sort dates as strings (yyyy-MM-dd format)
      
      if (deliveryDates.length > 0) {
        earliestDeliveryDate = deliveryDates[0]; // First date after sorting
      }
    }

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
      deliveryDate: earliestDeliveryDate, // Set earliest delivery date from items
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
    const orderItemIds = []; // Track order item IDs for linking additional costs

    for (const item of Item) {
      const orderItemId = await getNextSequenceValue('orderItemId');
      orderItemIds.push(orderItemId);
      
      const orderItemMeasurementId = await getNextSequenceValue(
        'orderItemMeasurementId'
      );
      const orderItemPatternId =
        await getNextSequenceValue('orderItemPatternId');

      // Order Item
      orderItems.push({
        orderItemId,
        orderId,
        dressTypeId: item?.dressTypeId ?? null,
        special_instructions: item?.special_instructions,
        recording: item?.recording,
        videoLink: item?.videoLink,
        Pictures: item?.Pictures,
        delivery_date: item?.delivery_date, // Use delivery_date (with underscore) to match frontend
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

    // Save additional costs to the new table
    if (AdditionalCosts && Array.isArray(AdditionalCosts) && AdditionalCosts.length > 0) {
      const additionalCostsToInsert = [];
      // Link additional costs to the first order item (or we could link to all items)
      const firstOrderItemId = orderItemIds.length > 0 ? orderItemIds[0] : null;
      
      if (firstOrderItemId) {
        for (const additionalCost of AdditionalCosts) {
          if (additionalCost?.additionalCostName && additionalCost?.additionalCost != null) {
            const orderItemAdditionalCostId = await getNextSequenceValue('orderItemAdditionalCostId');
            additionalCostsToInsert.push({
              orderItemAdditionalCostId,
              orderItemId: firstOrderItemId,
              orderId,
              additionalCostName: additionalCost.additionalCostName,
              additionalCost: additionalCost.additionalCost,
              owner: orderDetails?.owner,
            });
          }
        }
        
        if (additionalCostsToInsert.length > 0) {
          await OrderItemAdditionalCostModel.insertMany(additionalCostsToInsert, { session });
        }
      }
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
    const OrderItemAdditionalCost = getOrderItemAdditionalCostModel(shop_id);
    const Customer = getCustomerModel(shop_id);

    // Get collection names explicitly for aggregation lookups
    const customerCollectionName = `customer_${shop_id}`;
    const orderItemCollectionName = `orderItem_${shop_id}`;
    const orderItemMeasurementCollectionName = `orderitemmeasurement_${shop_id}`;
    const orderItemPatternCollectionName = `orderitempattern_${shop_id}`;
    const orderItemAdditionalCostCollectionName = `orderitemadditionalcost_${shop_id}`;

    // Query params
    const { orderId, status, filterType } = queryParams;

    // Extract searchKeyword BEFORE buildQueryOptions to prevent it from being used in base query
    const searchKeyword = queryParams?.searchKeyword || '';
    logger.debug('Search keyword received', { searchKeyword });
    
    // Remove searchKeyword from queryParams for buildQueryOptions to avoid owner search conflict
    const queryParamsWithoutSearch = { ...queryParams };
    delete queryParamsWithoutSearch.searchKeyword;
    
    const searchableFields = ['owner'];
    const numericFields = ['orderId'];
    const options = buildQueryOptions(
      queryParamsWithoutSearch, // Use queryParams without searchKeyword
      'createdAt',
      searchableFields,
      numericFields
    );

    // Base query for countDocuments (exclude customer search - will be done in aggregation)
    const baseQuery = { ...options.search, ...options.booleanFilters };
    if (orderId) baseQuery['orderId'] = Number(orderId);
    if (status) baseQuery['status'] = status;

    // Handle date filters
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEnd = new Date(today);
    todayEnd.setHours(23, 59, 59, 999);
    
    const weekStart = new Date(today);
    weekStart.setDate(today.getDate() - today.getDay()); // Start of week (Sunday)
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);

    if (filterType === 'createdToday') {
      baseQuery['createdAt'] = {
        $gte: today,
        $lte: todayEnd,
      };
    }

    // For single order queries, limit to 1 early for better performance
    const isSingleOrderQuery = !!orderId;

    // Build search match conditions if search keyword exists
    let searchMatchStage = null;
    if (searchKeyword && searchKeyword.trim()) {
      const trimmedKeyword = searchKeyword.trim();
      const numericOnly = trimmedKeyword.replace(/[^0-9]/g, '');
      const last10Digits = numericOnly.length >= 10 ? numericOnly.slice(-10) : '';
      
      // Build search conditions array
      const searchConditions = [
        // Search by customer name (case-insensitive, partial match)
        { customer_name: { $regex: trimmedKeyword, $options: 'i' } },
        // Search by owner (case-insensitive, partial match)
        { owner: { $regex: trimmedKeyword, $options: 'i' } },
      ];
      
      // Add mobile search conditions if there are numbers in the search term
      if (numericOnly.length > 0) {
        // Match exact mobile number (with or without + prefix)
        const mobileWithPlus = trimmedKeyword.replace(/[^0-9+]/g, '');
        if (mobileWithPlus.length > 0) {
          searchConditions.push({
            customer_mobile: { $regex: mobileWithPlus, $options: 'i' }
          });
        }
        
        // Match last 10 digits if search term has 10+ digits (handles country code)
        if (last10Digits.length === 10) {
          searchConditions.push({
            customer_mobile: { $regex: last10Digits, $options: 'i' }
          });
        }
        
        // Match any numeric part of mobile (for partial searches)
        searchConditions.push({
          customer_mobile: { $regex: numericOnly, $options: 'i' }
        });
      }
      
      searchMatchStage = {
        $match: {
          $or: searchConditions,
        },
      };
      logger.debug('Search conditions', { searchConditions, searchMatchStage });
    } else {
      logger.debug('No search keyword provided');
    }

    // Main aggregation pipeline
    const aggregatePipeline = [
      { $match: baseQuery },
      // For single order queries, limit early to improve performance
      ...(isSingleOrderQuery ? [{ $limit: 1 }] : []),
      {
        $lookup: {
          from: customerCollectionName,
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
          customer_name: { $ifNull: ['$customerInfo.name', ''] },
          customer_mobile: { $ifNull: ['$customerInfo.mobile', ''] },
        },
      },
      // Add search filter for customer name and mobile after customer lookup
      ...(searchMatchStage ? [searchMatchStage] : []),
      {
        $unset: 'customerInfo',
      },
      {
        $lookup: {
          from: orderItemCollectionName,
          localField: 'orderId',
          foreignField: 'orderId',
          as: 'items',
        },
      },
      {
        $unwind: {
          path: '$items',
          preserveNullAndEmptyArrays: true,
        },
      },
      {
        $lookup: {
          from: orderItemMeasurementCollectionName,
          let: { 
            orderId: '$orderId',
            orderItemId: '$items.orderItemId'
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
            { $limit: 1 },
          ],
          as: 'measurementArray',
        },
      },
      {
        $addFields: {
          'items.measurement': {
            $cond: {
              if: { $gt: [{ $size: '$measurementArray' }, 0] },
              then: [{ $arrayElemAt: ['$measurementArray', 0] }],
              else: []
            }
          },
          measurementArray: '$$REMOVE',
        },
      },
      {
        $lookup: {
          from: orderItemPatternCollectionName,
          let: { 
            orderId: '$orderId',
            orderItemId: '$items.orderItemId'
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
          as: 'patternArray',
        },
      },
      {
        $addFields: {
          'items.Pattern': '$patternArray',
          patternArray: '$$REMOVE',
        },
      },
      {
        $group: {
          _id: '$_id',
          orderId: { $first: '$orderId' },
          customerId: { $first: '$customerId' },
          customer_name: { $first: '$customer_name' },
          shop_id: { $first: '$shop_id' },
          branchId: { $first: '$branchId' },
          stitchingType: { $first: '$stitchingType' },
          noOfMeasurementDresses: { $first: '$noOfMeasurementDresses' },
          quantity: { $first: '$quantity' },
          urgent: { $first: '$urgent' },
          status: { $first: '$status' },
          estimationCost: { $first: '$estimationCost' },
          advancereceived: { $first: '$advancereceived' },
          advanceReceivedDate: { $first: '$advanceReceivedDate' },
          gst: { $first: '$gst' },
          gst_amount: { $first: '$gst_amount' },
          courier: { $first: '$courier' },
          courierCharge: { $first: '$courierCharge' },
          discount: { $first: '$discount' },
          owner: { $first: '$owner' },
          createdAt: { $first: '$createdAt' },
          updatedAt: { $first: '$updatedAt' },
          items: { $push: '$items' },
        },
      },
      {
        $lookup: {
          from: orderItemAdditionalCostCollectionName,
          localField: 'orderId',
          foreignField: 'orderId',
          as: 'additionalCosts',
        },
      },
      // Add delivery date filter after items are grouped
      ...(filterType === 'deliveryToday' || filterType === 'deliveryThisWeek' ? [{
        $match: {
          $expr: {
            $gt: [{
              $size: {
                $filter: {
                  input: '$items',
                  as: 'item',
                  cond: filterType === 'deliveryToday' 
                    ? {
                        $eq: [
                          '$$item.delivery_date',
                          new Date().toISOString().split('T')[0]
                        ]
                      }
                    : {
                        $and: [
                          { $gte: ['$$item.delivery_date', weekStart.toISOString().split('T')[0]] },
                          { $lte: ['$$item.delivery_date', weekEnd.toISOString().split('T')[0]] }
                        ]
                      }
                }
              }
            }, 0]
          }
        }
      }] : []),
      // Apply sorting and other options
      { $sort: options.sort || { createdAt: -1 } },
    ];

    // For accurate count when searching by customer, we need to count after aggregation
    // Create a count pipeline (same as main pipeline but with $count at the end)
    const countPipeline = [
      ...aggregatePipeline.slice(0, -1), // Remove the $sort stage for count
      { $count: 'total' },
    ];

    // Get total count using aggregation
    const countResult = await Order.aggregate(countPipeline);
    const total = countResult.length > 0 ? countResult[0].total : 0;

    // Apply pagination to the main pipeline
    const page = options.page || 1;
    const limit = options.limit || 10;
    const skip = (page - 1) * limit;

    // Add pagination stages
    const finalPipeline = [
      ...aggregatePipeline,
      { $skip: skip },
      { $limit: limit },
    ];

    // Execute aggregation
    logger.debug('Executing aggregation pipeline');
    const data = await Order.aggregate(finalPipeline);
    logger.debug('Aggregation completed', {
      returned: data.length,
      total,
    });
    
    // Log first order's customer info if available for debugging
    if (data.length > 0 && searchKeyword) {
      const firstOrder = data[0];
      logger.debug('Sample order data', {
        customer_name: firstOrder.customer_name,
        customer_mobile: firstOrder.customer_mobile,
        owner: firstOrder.owner,
      });
    }

    return {
      total,
      pageSize: limit,
      pageNumber: page,
      data,
    };
  } catch (error) {
    logger.error('Error in getAllOrdersService', error);
    throw error;
  }
};

const updateOrderService = async (orderId, orderData, shop_id) => {
  const session = await Order.startSession();
  session.startTransaction();

  try {
    const { Order: orderDetails, Item, AdditionalCosts } = orderData || {};

    // Check if shop exists
    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    // Initialize models
    const OrderModel = getOrderModel(shop_id);
    const OrderItemModel = getOrderItemModel(shop_id);
    const OrderItemMeasurementModel = getOrderItemMeasurementModel(shop_id);
    const OrderItemPatternModel = getOrderItemPatternModel(shop_id);
    const OrderItemAdditionalCostModel = getOrderItemAdditionalCostModel(shop_id);

    // Check if order exists
    const existingOrder = await OrderModel.findOne({ orderId });
    if (!existingOrder) throw new Error(`Order with ID ${orderId} not found`);

    // Calculate earliest delivery date from all items
    let earliestDeliveryDate = null;
    if (Item && Item.length > 0) {
      const deliveryDates = Item
        .map(item => item?.delivery_date)
        .filter(date => date && date.trim() !== '')
        .sort(); // Sort dates as strings (yyyy-MM-dd format)
      
      if (deliveryDates.length > 0) {
        earliestDeliveryDate = deliveryDates[0]; // First date after sorting
      }
    }

    // Update the main Order document
    Object.assign(existingOrder, {
      ...orderDetails,
      courier: orderDetails?.Courier, // ensure consistency in field name
      deliveryDate: earliestDeliveryDate, // Set earliest delivery date from items
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
      
      // Require IDs for update of regular items
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
            delivery_date: item.delivery_date, // Use delivery_date (with underscore) to match frontend
            amount: item.amount,
            status: item.status,
            owner: item.owner,
            isAdditionalCost: item?.isAdditionalCost ?? false,
            additionalCostDescription: item?.additionalCostDescription ?? null,
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

    // Handle additional costs - delete existing and recreate
    if (AdditionalCosts !== undefined) {
      // Delete all existing additional costs for this order
      await OrderItemAdditionalCostModel.deleteMany({ orderId }, { session });
      
      // Get the first order item ID to link additional costs to
      const firstOrderItem = await OrderItemModel.findOne({ orderId }).sort({ orderItemId: 1 });
      const firstOrderItemId = firstOrderItem?.orderItemId;
      
      if (firstOrderItemId && Array.isArray(AdditionalCosts) && AdditionalCosts.length > 0) {
        const additionalCostsToInsert = [];
        for (const additionalCost of AdditionalCosts) {
          if (additionalCost?.additionalCostName && additionalCost?.additionalCost != null) {
            const orderItemAdditionalCostId = await getNextSequenceValue('orderItemAdditionalCostId');
            additionalCostsToInsert.push({
              orderItemAdditionalCostId,
              orderItemId: firstOrderItemId,
              orderId,
              additionalCostName: additionalCost.additionalCostName,
              additionalCost: additionalCost.additionalCost,
              owner: orderDetails?.owner,
            });
          }
        }
        
        if (additionalCostsToInsert.length > 0) {
          await OrderItemAdditionalCostModel.insertMany(additionalCostsToInsert, { session });
        }
      }
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
