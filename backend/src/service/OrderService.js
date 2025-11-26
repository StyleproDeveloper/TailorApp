const Order = require('../models/OrderModel');
const orderItemModel = require('../models/OrderItemModel');
const OrderItemMeasurement = require('../models/OrderItemMeasurementModel');
const OrderItemPattern = require('../models/OrderItemPatternModel');
const OrderItemAdditionalCost = require('../models/OrderItemAdditionalCostModel');
const Customer = require('../models/CustomerModel');
const ShopInfo = require('../models/ShopModel');
const { getNextSequenceValue } = require('./sequenceService');
const { isShopExists } = require('../utils/Helper');
const { default: mongoose } = require('mongoose');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');
const { createShopBucket, bucketExists, uploadToS3 } = require('../utils/s3Service');
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
  const session = await mongoose.startSession();
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
      // Handle both Pictures and pictures field names for backward compatibility
      const pictures = item?.pictures || item?.Pictures || [];
      orderItems.push({
        orderItemId,
        orderId,
        dressTypeId: item?.dressTypeId ?? null,
        special_instructions: item?.special_instructions,
        recording: item?.recording,
        videoLink: item?.videoLink,
        pictures: pictures,
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

    // Ensure S3 bucket exists and create order folder structure
    try {
      const shop = await ShopInfo.findOne({ shop_id: Number(shop_id) });
      if (!shop) {
        logger.warn('Shop not found for S3 bucket setup', { shop_id, orderId });
      } else {
        let bucketName = shop.s3BucketName;
        
        // Check AWS credentials
        const hasAwsCredentials = process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY;
        if (!hasAwsCredentials) {
          logger.warn('AWS credentials not configured, skipping S3 folder creation', { shop_id, orderId });
        } else {
          // Create bucket if it doesn't exist or verify it exists
          if (!bucketName) {
            logger.info('S3 bucket name not found in shop, creating new bucket...', { shop_id, shopName: shop.shopName });
            bucketName = await createShopBucket(shop.shopName || shop.yourName, shop_id);
            
            // Update shop with bucket name
            shop.s3BucketName = bucketName;
            await shop.save();
            logger.info('S3 bucket created and saved to shop', { shop_id, bucketName });
          } else {
            // Verify bucket exists
            const exists = await bucketExists(bucketName);
            if (!exists) {
              logger.warn('S3 bucket name exists in shop but bucket not found in AWS, attempting to create...', { shop_id, bucketName });
              try {
                bucketName = await createShopBucket(shop.shopName || shop.yourName, shop_id);
                shop.s3BucketName = bucketName;
                await shop.save();
                logger.info('S3 bucket recreated and saved to shop', { shop_id, bucketName });
              } catch (createError) {
                logger.error('Failed to recreate S3 bucket', {
                  shop_id,
                  orderId,
                  bucketName,
                  error: createError.message,
                  stack: createError.stack,
                });
                // Continue - will try to create folder anyway
              }
            } else {
              logger.debug('S3 bucket verified to exist', { shop_id, bucketName });
            }
          }
          
          // Create a placeholder file in the order folder to make it visible in S3
          // This ensures the folder structure exists even before media is uploaded
          if (bucketName) {
            try {
              const orderFolderKey = `order_${orderId}/.folder`;
              const placeholderContent = Buffer.from(`Order ${orderId} created on ${new Date().toISOString()}`);
              
              await uploadToS3(
                bucketName,
                orderFolderKey,
                placeholderContent,
                'text/plain',
                {
                  shopId: shop_id.toString(),
                  orderId: orderId.toString(),
                  type: 'folder-marker',
                }
              );
              
              logger.info('Order folder structure created in S3', {
                shop_id,
                orderId,
                bucketName,
                folderKey: orderFolderKey,
              });
            } catch (s3Error) {
              // Log error with full details but don't fail order creation
              logger.error('Failed to create order folder in S3', {
                shop_id,
                orderId,
                bucketName,
                folderKey: `order_${orderId}/.folder`,
                error: s3Error.message,
                errorName: s3Error.name,
                errorCode: s3Error.code,
                stack: s3Error.stack,
              });
            }
          } else {
            logger.warn('Bucket name is empty, cannot create order folder', { shop_id, orderId });
          }
        }
      }
    } catch (s3SetupError) {
      // Log error with full details but don't fail order creation if S3 setup fails
      logger.error('S3 bucket setup failed', {
        shop_id,
        orderId,
        error: s3SetupError.message,
        errorName: s3SetupError.name,
        stack: s3SetupError.stack,
      });
    }

    // Fetch the created order items to return with orderItemIds
    const createdOrderItems = await OrderItemModel.find({ orderId }).select('orderItemId dressTypeId').lean();

    return { 
      message: 'Order created successfully', 
      order,
      orderId: order.orderId,
      Item: createdOrderItems, // Return items with orderItemIds for media upload
    };
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
          from: OrderItem.collection.name,
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
          from: OrderItemMeasurement.collection.name,
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
          from: OrderItemPattern.collection.name,
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
          paidAmount: { $first: '$paidAmount' },
          owner: { $first: '$owner' },
          createdAt: { $first: '$createdAt' },
          updatedAt: { $first: '$updatedAt' },
          items: { $push: '$items' },
        },
      },
      {
        $addFields: {
          paidAmount: { $ifNull: ['$paidAmount', 0] },
        },
      },
      {
        $lookup: {
          from: OrderItemAdditionalCost.collection.name,
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
      // Add all delivered filter - orders where all items are delivered
      ...(filterType === 'allDelivered' ? [{
        $match: {
          $expr: {
            $and: [
              { $gt: [{ $size: '$items' }, 0] }, // Order must have items
              { $eq: [
                  { $size: '$items' }, // Total number of items
                  { $size: {
                      $filter: {
                        input: '$items',
                        as: 'item',
                        cond: { $eq: ['$$item.delivered', true] }
                      }
                    }
                  } // Number of delivered items
                ]
              } // All items must be delivered
            ]
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
    const session = await mongoose.startSession();
    session.startTransaction();

  try {
    // Ensure orderId and shop_id are numbers
    const numericOrderId = typeof orderId === 'string' ? parseInt(orderId, 10) : orderId;
    const numericShopId = typeof shop_id === 'string' ? parseInt(shop_id, 10) : shop_id;
    
    if (isNaN(numericOrderId)) {
      throw new Error(`Invalid orderId: ${orderId}`);
    }
    if (isNaN(numericShopId)) {
      throw new Error(`Invalid shop_id: ${shop_id}`);
    }
    
    const { Order: orderDetails, Item, AdditionalCosts } = orderData || {};

    logger.info('Updating order', { orderId: numericOrderId, shop_id: numericShopId, itemCount: Item?.length || 0 });

    // Check if shop exists
    const shopExists = await isShopExists(numericShopId);
    if (!shopExists) throw new Error(`Shop with ID ${numericShopId} does not exist`);

    // Initialize models
    const OrderModel = getOrderModel(numericShopId);
    const OrderItemModel = getOrderItemModel(numericShopId);
    const OrderItemMeasurementModel = getOrderItemMeasurementModel(numericShopId);
    const OrderItemPatternModel = getOrderItemPatternModel(numericShopId);
    const OrderItemAdditionalCostModel = getOrderItemAdditionalCostModel(numericShopId);

    // Check if order exists
    const existingOrder = await OrderModel.findOne({ orderId: numericOrderId });
    if (!existingOrder) throw new Error(`Order with ID ${numericOrderId} not found`);

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

    // Preserve critical fields that shouldn't be changed during update
    // If customerId is not provided or is 0, preserve the existing customerId
    const customerIdToUse = (orderDetails?.customerId && orderDetails.customerId !== 0) 
      ? orderDetails.customerId 
      : existingOrder.customerId;
    
    // Preserve branchId if not provided
    const branchIdToUse = orderDetails?.branchId !== undefined 
      ? orderDetails.branchId 
      : existingOrder.branchId;

    // Update the main Order document
    // Only update fields that are provided, preserve critical fields
    Object.assign(existingOrder, {
      ...orderDetails,
      // Preserve critical fields
      orderId: existingOrder.orderId, // Never change orderId
      customerId: customerIdToUse, // Preserve existing customerId if not provided or is 0
      branchId: branchIdToUse, // Preserve branchId if not provided
      courier: orderDetails?.Courier !== undefined ? orderDetails.Courier : existingOrder.courier, // ensure consistency in field name
      deliveryDate: earliestDeliveryDate || existingOrder.deliveryDate, // Set earliest delivery date from items or preserve existing
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
      // Check if this is a new item (no orderItemId or orderItemId is 0/null)
      // Handle both undefined and null cases, as well as 0
      // Also check if orderItemId exists in Measurement or Pattern as fallback
      let itemOrderItemId = item?.orderItemId;
      
      // Fallback: Try to get orderItemId from Measurement or Pattern if not at item level
      if ((itemOrderItemId === undefined || itemOrderItemId === null || itemOrderItemId === 0) && item?.Measurement) {
        // Check if there's an orderItemId in the measurement (though this shouldn't happen)
        const measurementOrderItemId = item.Measurement.orderItemId;
        if (measurementOrderItemId && measurementOrderItemId > 0) {
          logger.warn('Found orderItemId in Measurement instead of item level', { 
            measurementOrderItemId,
            itemKeys: Object.keys(item)
          });
          itemOrderItemId = measurementOrderItemId;
        }
      }
      
      const isNewItem = itemOrderItemId === undefined || itemOrderItemId === null || itemOrderItemId === 0;
      
      logger.debug('Processing item', { 
        isNewItem, 
        orderItemId: itemOrderItemId,
        orderItemIdType: typeof itemOrderItemId,
        itemOrderItemIdSource: item?.orderItemId ? 'item level' : 'not found',
        hasMeasurement: !!item?.Measurement,
        hasPattern: !!item?.Pattern,
        patternLength: item?.Pattern?.length || 0,
        dressTypeId: item?.dressTypeId,
        measurementKeys: item?.Measurement ? Object.keys(item.Measurement) : [],
        itemKeys: Object.keys(item || {}),
      });
      
      if (isNewItem) {
        // Create new item (similar to createOrderService)
        logger.info('Creating new item', { dressTypeId: item?.dressTypeId });
        const orderItemId = await getNextSequenceValue('orderItemId');
        const orderItemMeasurementId = await getNextSequenceValue('orderItemMeasurementId');
        const orderItemPatternId = await getNextSequenceValue('orderItemPatternId');

        // Create Order Item
        // Handle both Pictures and pictures field names for backward compatibility
        const pictures = item?.pictures || item?.Pictures || [];
        await OrderItemModel.create([{
          orderItemId,
          orderId: numericOrderId,
          dressTypeId: item?.dressTypeId ?? null,
          special_instructions: item?.special_instructions,
          recording: item?.recording,
          videoLink: item?.videoLink,
          pictures: pictures,
          delivery_date: item?.delivery_date,
          amount: item?.amount,
          status: item?.status,
          owner: item?.owner,
          orderItemMeasurementId,
          orderItemPatternId,
          isAdditionalCost: item?.isAdditionalCost ?? false,
          additionalCostDescription: item?.additionalCostDescription ?? null,
        }], { session });

        // Create Measurement
        // Exclude orderItemMeasurementId, orderId, and orderItemId from spread to prevent overwriting generated IDs
        const { orderItemMeasurementId: _, orderId: __, orderItemId: ___, ...measurementData } = item?.Measurement || {};
        const measurement = {
          orderItemMeasurementId,
          orderId: numericOrderId,
          orderItemId,
          customerId: orderDetails?.customerId,
          dressTypeId: item?.dressTypeId,
          owner: item?.owner,
          ...measurementData,
        };
        await OrderItemMeasurementModel.create([measurement], { session });

        // Create Pattern
        // Filter out invalid patterns (empty category or name)
        const validPatterns = Array.isArray(item?.Pattern)
          ? item?.Pattern
              .filter((p) => p && (p?.category || p?.name))
              .map((p) => ({
                category: p?.category || 'Unknown',
                name: Array.isArray(p?.name) 
                  ? (p?.name.length > 0 ? p?.name : ['None'])
                  : (p?.name ? [p?.name] : ['None']),
              }))
          : [];
        
        const pattern = {
          orderItemPatternId,
          orderId: numericOrderId,
          orderItemId,
          owner: item?.owner,
          patterns: validPatterns.length > 0 ? validPatterns : [{ category: 'Unknown', name: ['None'] }],
        };
        
        logger.debug('Creating pattern for new item', {
          orderItemId,
          patternCount: validPatterns.length,
          patterns: validPatterns,
        });
        
        await OrderItemPatternModel.create([pattern], { session });
      } else {
        // Update existing item (requires IDs)
        // Use the resolved itemOrderItemId
        const orderItemIdForUpdate = itemOrderItemId;
        const hasMeasurementId = item?.Measurement?.orderItemMeasurementId;
        const hasPattern = item.Pattern?.length > 0;
        const hasPatternId = item.Pattern?.[0]?.orderItemPatternId;
        
        logger.debug('Validating existing item IDs', {
          orderItemId: orderItemIdForUpdate,
          hasMeasurementId: !!hasMeasurementId,
          hasPattern,
          hasPatternId: !!hasPatternId,
          measurementId: hasMeasurementId,
          patternId: hasPatternId
        });
        
        if (!hasMeasurementId || !hasPattern || !hasPatternId) {
          const missingFields = [];
          if (!hasMeasurementId) missingFields.push('orderItemMeasurementId in Measurement');
          if (!hasPattern) missingFields.push('Pattern array (empty or missing)');
          if (!hasPatternId) missingFields.push('orderItemPatternId in Pattern[0]');
          
          logger.error('Missing IDs for update', {
            orderItemId: orderItemIdForUpdate,
            missingFields,
            itemOrderItemId: item?.orderItemId,
            itemKeys: Object.keys(item || {}),
            measurementKeys: item?.Measurement ? Object.keys(item.Measurement) : [],
            patternKeys: item?.Pattern?.[0] ? Object.keys(item.Pattern[0]) : [],
            item: JSON.stringify(item, null, 2)
          });
          
          throw new Error(`Missing IDs for update. Existing items require orderItemMeasurementId and orderItemPatternId. Missing: ${missingFields.join(', ')}`);
        }

        const orderItemId = orderItemIdForUpdate;
        const orderItemMeasurementId = item.Measurement.orderItemMeasurementId;
        const orderItemPatternId = item.Pattern[0].orderItemPatternId;

        // Update Order Item
        // Handle both Pictures and pictures field names for backward compatibility
        const pictures = item?.pictures || item?.Pictures || [];
        await OrderItemModel.updateOne(
          { orderItemId, orderId: numericOrderId },
          {
            $set: {
              dressTypeId: item.dressTypeId,
              special_instructions: item.special_instructions,
              recording: item.recording,
              videoLink: item.videoLink,
              pictures: pictures,
              delivery_date: item.delivery_date,
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
        // Exclude orderItemMeasurementId, orderId, and orderItemId from spread to prevent overwriting
        const { orderItemMeasurementId: _, orderId: __, orderItemId: ___, ...measurementUpdateData } = item.Measurement || {};
        await OrderItemMeasurementModel.updateOne(
          { orderItemMeasurementId, orderId: numericOrderId, orderItemId },
          {
            $set: {
              owner: item.owner,
              ...measurementUpdateData,
            },
          },
          { session }
        );

        // Update Pattern
        await OrderItemPatternModel.updateOne(
          { orderItemPatternId, orderId: numericOrderId, orderItemId },
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
    }

    // Handle additional costs - delete existing and recreate
    if (AdditionalCosts !== undefined) {
      // Delete all existing additional costs for this order
      await OrderItemAdditionalCostModel.deleteMany({ orderId: numericOrderId }, { session });
      
      // Get the first order item ID to link additional costs to
      const firstOrderItem = await OrderItemModel.findOne({ orderId: numericOrderId }).sort({ orderItemId: 1 });
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
    logger.error('Error updating order', {
      orderId: numericOrderId,
      shop_id: numericShopId,
      error: err.message,
      stack: err.stack,
      errorName: err.name,
      errorCode: err.code,
      validationDetails: err.details
    });
    
    // Provide more specific error messages
    if (err.name === 'ValidationError' || err.isJoi) {
      const errorMessage = err.details 
        ? err.details.map(d => d.message).join(', ')
        : err.message || 'Validation error';
      throw new Error(`Validation failed: ${errorMessage}`);
    }
    
    throw err;
  }
};

const updateOrderItemDeliveryStatusService = async (shop_id, orderItemId, deliveryData) => {
  try {
    // Check if shop exists
    const shopExists = await isShopExists(shop_id);
    if (!shopExists) throw new Error(`Shop with ID ${shop_id} does not exist`);

    const OrderItemModel = getOrderItemModel(shop_id);
    const OrderModel = getOrderModel(shop_id);

    // First, get the order item to find the orderId
    const existingItem = await OrderItemModel.findOne({ orderItemId });
    if (!existingItem) {
      throw new Error(`Order item with ID ${orderItemId} not found`);
    }

    const orderId = existingItem.orderId;

    const updateData = {};
    if (deliveryData.delivered !== undefined) {
      updateData.delivered = deliveryData.delivered;
    }
    if (deliveryData.actualDeliveryDate !== undefined) {
      updateData.actualDeliveryDate = deliveryData.actualDeliveryDate 
        ? new Date(deliveryData.actualDeliveryDate) 
        : null;
    }

    const updatedItem = await OrderItemModel.findOneAndUpdate(
      { orderItemId },
      { $set: updateData },
      { new: true }
    );

    if (!updatedItem) {
      throw new Error(`Order item with ID ${orderItemId} not found`);
    }

    // Check if all items in the order are delivered
    if (deliveryData.delivered === true) {
      const allItems = await OrderItemModel.find({ orderId });
      
      // Check if all items are delivered
      const allDelivered = allItems.length > 0 && allItems.every(item => item.delivered === true);
      
      if (allDelivered) {
        // Update order status to "delivered"
        await OrderModel.findOneAndUpdate(
          { orderId },
          { $set: { status: 'delivered' } },
          { new: true }
        );
        logger.info('Order status automatically updated to "delivered"', {
          shop_id,
          orderId,
          orderItemId,
        });
      }
    } else if (deliveryData.delivered === false) {
      // If an item is marked as not delivered, and order was "delivered", change it back to previous status
      // We'll set it to "completed" or keep current status if not "delivered"
      const order = await OrderModel.findOne({ orderId });
      if (order && order.status === 'delivered') {
        // Change back to "completed" when an item is unmarked as delivered
        await OrderModel.findOneAndUpdate(
          { orderId },
          { $set: { status: 'completed' } },
          { new: true }
        );
        logger.info('Order status changed from "delivered" to "completed"', {
          shop_id,
          orderId,
          orderItemId,
        });
      }
    }

    return updatedItem;
  } catch (error) {
    throw error;
  }
};

module.exports = {
  getOrderModel,
  createOrderService,
  getAllOrdersService,
  updateOrderService,
  updateOrderItemDeliveryStatusService,
};
