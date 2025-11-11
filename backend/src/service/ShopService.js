const ShopInfo = require('../models/ShopModel');
const { getDefaultRoles } = require('../utils/DefaultValuesTables');
const DressTypeSchema = require('../models/DressTypeModel').schema;
const CustomerSchema = require('../models/CustomerModel').schema;
const DressPatternSchema = require('../models/DresspatternModel').schema;
const DressTypeDresspatternSchema =
  require('../models/DressTypeDresspatternModel').schema;
const DressTypeMeasurementSchema =
  require('../models/DressTypeMeasurementModel').schema;
const MeasurementHistorySchema =
  require('../models/MeasurementHistoryModel').schema;
const MeasurementSchema = require('../models/MeasurementModel').schema;
const OrderItemSchema = require('../models/OrderItemModel').schema;
const OrderSchema = require('../models/OrderModel').schema;
const OrderItemAdditionalCostSchema = require('../models/OrderItemAdditionalCostModel').schema;
const OrderMediaSchema = require('../models/OrderMediaModel').schema;
const RoleSchema = require('../models/RoleModel').schema;
const { getDynamicModel } = require('../utils/DynamicModel');
const { getNextSequenceValue } = require('./sequenceService');
const { SubscriptionEnumMapping } = require('../utils/CommonEnumValues');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');
const { createUserService } = require('./UserService');
const { getRoleModel } = require('./RoleService');
const mongoose = require('mongoose');
const logger = require('../utils/logger');

const createShopService = async (shopData) => {
  try {
    const shopId = await getNextSequenceValue('shopId');
    const defaultRoles = await getDefaultRoles();
    // Ensure shopId is valid before proceeding
    if (!shopId) {
      throw new Error('Invalid shopId: Cannot create shop-related collections');
    }

    let { subscriptionType } = shopData;

    // Convert number to enum string if needed
    if (typeof subscriptionType === 'number') {
      subscriptionType =
        SubscriptionEnumMapping[subscriptionType] || SubscriptionEnum.TRIAL; // Default to TRIAL if invalid
    }
    logger.debug('Default roles initialized', { count: defaultRoles.length });

    const newShop = new ShopInfo({
      ...shopData,
      shop_id: shopId,
      subscriptionType,
    });

    // Dynamically initialize  collections based on shopId
    const initializeCollections = async () => {
      // Create dressType collection and copy from masterdresstype
      const dressTypeModel = await getDynamicModel('DressType', DressTypeSchema, `dressType_${shopId}`);
      
      // Copy records from masterdresstype to the new dressType collection
      try {
        const db = mongoose.connection.db;
        const masterDressTypes = await db.collection('masterdresstype').find({}).toArray();
        
        if (masterDressTypes && masterDressTypes.length > 0) {
          // Remove _id field to let MongoDB generate new ones
          const documentsToInsert = masterDressTypes.map(doc => {
            const { _id, ...rest } = doc;
            return rest;
          });
          
          if (documentsToInsert.length > 0) {
            await dressTypeModel.insertMany(documentsToInsert);
            logger.info(`Copied dress types from masterdresstype`, {
              shopId,
              count: documentsToInsert.length,
            });
          }
        } else {
          logger.warn('No dress types found in masterdresstype collection', { shopId });
        }
      } catch (copyError) {
        logger.error('Error copying dress types from masterdresstype', copyError);
        // Continue even if copy fails - collection is still created
      }
      
      await getDynamicModel('Customer', CustomerSchema, `customer_${shopId}`);
      await getDynamicModel(
        'Dresspattern',
        DressPatternSchema,
        `dresspattern_${shopId}`
      );
      await getDynamicModel(
        'DressTypeDressPattern',
        DressTypeDresspatternSchema,
        `dressTypeDressPattern_${shopId}`
      );
      await getDynamicModel(
        'DressTypeMeasurement',
        DressTypeMeasurementSchema,
        `dressTypeMeasurement_${shopId}`
      );
      await getDynamicModel(
        'MeasurementHistory',
        MeasurementHistorySchema,
        `measurementHistory_${shopId}`
      );
      await getDynamicModel(
        'Measurements',
        MeasurementSchema,
        `measurement_${shopId}`
      );
      await getDynamicModel('OrderItem', OrderItemSchema, `orderItem_${shopId}`);
      await getDynamicModel('Order', OrderSchema, `order_${shopId}`);
      await getDynamicModel('OrderItemAdditionalCost', OrderItemAdditionalCostSchema, `orderitemadditionalcost_${shopId}`);
      await getDynamicModel('OrderMedia', OrderMediaSchema, `ordermedia_${shopId}`);
      // Await Role creation to ensure roles are saved before user creation
      await getDynamicModel('Role', RoleSchema, `role_${shopId}`, defaultRoles);
    };

    await initializeCollections();

    const savedShop = await newShop.save();

    // After shop is created, create a user with Owner role
    try {
      // Get the Role model for this shop
      const RoleModel = getRoleModel(shopId);
      
      // Find the Owner role (first role created is Owner)
      const ownerRole = await RoleModel.findOne({ name: 'Owner' });
      
      if (!ownerRole) {
        logger.warn('Owner role not found for shop. User creation skipped.', { shopId });
        return savedShop;
      }

      // Prepare user data from shop data
      const userData = {
        shopId: shopId,
        branchId: shopData.branch_id || 1, // Default to 1 if not provided
        mobile: shopData.mobile,
        name: shopData.yourName,
        roleId: ownerRole.roleId,
        secondaryMobile: shopData.secondaryMobile || null,
        email: shopData.email || null,
        addressLine1: shopData.addressLine1 || null,
        street: shopData.street || null,
        city: shopData.city || null,
        postalCode: shopData.postalCode || null,
      };

      // Create the user
      await createUserService(userData);
      logger.info('User created successfully for shop with Owner role', {
        shopId,
        userId: userData.mobile,
      });
    } catch (userError) {
      // Log error but don't fail shop creation if user creation fails
      logger.error('Error creating user for shop', userError, { shopId });
      // Continue - shop is already created
    }

    return savedShop;
  } catch (error) {
    throw error;
  }
};

const getShopsService = async (queryParams) => {
  try {
    const searchbleFields = [
      'yourName',
      'shopName',
      'code',
      'shopType',
      'mobile',
      'secondaryMobile',
      'email',
      'website',
      'instagram_url',
      'facebook_url',
      'addressLine1',
      'street',
      'city',
      'state',
      // 'subscriptionType',
      // 'subscriptionEndDate',
      // 'setupComplete',
    ];
    const numericFields = ['shop_id', 'branch_id', 'postalCode'];
    // Get the query options
    const options = buildQueryOptions(
      queryParams,
      'shopName',
      searchbleFields,
      numericFields
    );

    // Merge boolean filters into the main query
    const query = { ...options?.search, ...options?.booleanFilters };

    return await paginate(ShopInfo, query, options);
  } catch (error) {
    throw error;
  }
};

const getShopByIdService = async (shop_id) => {
  try {
    const numericShopId = isNaN(Number(shop_id)) ? shop_id : Number(shop_id);
    return await ShopInfo.findOne({ shop_id: numericShopId });
  } catch (error) {
    throw error;
  }
};

const updateShopService = async (shop_id, shopData) => {
  try {
    const numericShopId = isNaN(Number(shop_id)) ? shop_id : Number(shop_id);
    return await ShopInfo.findOneAndUpdate(
      { shop_id: numericShopId },
      shopData,
      { new: true, runValidators: true }
    );
  } catch (error) {
    throw error;
  }
};

const deleteShopService = async (shop_id) => {
  try {
    const numericShopId = isNaN(Number(shop_id)) ? shop_id : Number(shop_id);
    return await ShopInfo.findOneAndDelete({ shop_id: numericShopId });
  } catch (error) {
    throw error;
  }
};

module.exports = {
  createShopService,
  getShopsService,
  getShopByIdService,
  updateShopService,
  deleteShopService,
};
