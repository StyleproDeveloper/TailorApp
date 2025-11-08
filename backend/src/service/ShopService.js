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
const RoleSchema = require('../models/RoleModel').schema;
const { getDynamicModel } = require('../utils/DynamicModel');
const { getNextSequenceValue } = require('./sequenceService');
const { SubscriptionEnumMapping } = require('../utils/CommonEnumValues');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');

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
    console.log('defaultRoles', defaultRoles);

    const newShop = new ShopInfo({
      ...shopData,
      shop_id: shopId,
      subscriptionType,
    });

    // Dynamically initialize  collections based on shopId
    const initializeCollections = () => {
      getDynamicModel('DressType', DressTypeSchema, `dressType_${shopId}`);
      getDynamicModel('Customer', CustomerSchema, `customer_${shopId}`);
      getDynamicModel(
        'Dresspattern',
        DressPatternSchema,
        `dresspattern_${shopId}`
      );
      getDynamicModel(
        'DressTypeDressPattern',
        DressTypeDresspatternSchema,
        `dressTypeDressPattern_${shopId}`
      );
      getDynamicModel(
        'DressTypeMeasurement',
        DressTypeMeasurementSchema,
        `dressTypeMeasurement_${shopId}`
      );
      getDynamicModel(
        'MeasurementHistory',
        MeasurementHistorySchema,
        `measurementHistory_${shopId}`
      );
      getDynamicModel(
        'Measurements',
        MeasurementSchema,
        `measurement_${shopId}`
      );
      getDynamicModel('OrderItem', OrderItemSchema, `orderItem_${shopId}`);
      getDynamicModel('Order', OrderSchema, `order_${shopId}`);
      getDynamicModel('OrderItemAdditionalCost', OrderItemAdditionalCostSchema, `orderitemadditionalcost_${shopId}`);
      getDynamicModel('Role', RoleSchema, `role_${shopId}`, defaultRoles);
    };

    await initializeCollections();

    return newShop.save();
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
