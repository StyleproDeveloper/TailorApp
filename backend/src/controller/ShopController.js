const {
  createShopService,
  getShopsService,
  getShopByIdService,
  updateShopService,
  deleteShopService,
} = require('../service/ShopService');
const { asyncHandler, CustomError } = require('../utils/error.handlers');

const createShop = asyncHandler(async (req, res) => {
  try {
    const shop = await createShopService(req.body);
    res.status(201).json({
      success: true,
      message: 'Shop created successfully',
      data: shop,
    });
  } catch (error) {
    // Check for MongoDB collection limit error
    if (error.message && error.message.includes('cannot create a new collection')) {
      throw new CustomError(
        'Database collection limit reached. Cannot create new shop. Please contact support or upgrade your MongoDB plan.',
        500,
        { details: error.message }
      );
    }
    throw error;
  }
});

const getShops = asyncHandler(async (req, res) => {
  const shops = await getShopsService(req?.query);
  res.status(200).json({
    success: true,
    ...shops,
  });
});

const getShopById = asyncHandler(async (req, res) => {
  const shop = await getShopByIdService(req.params.id);
  if (!shop) {
    throw new CustomError('Shop not found', 404);
  }
  res.status(200).json({
    success: true,
    data: shop,
  });
});

const updateShop = asyncHandler(async (req, res) => {
  const payload = { ...req.body };

  // Normalize URLs (trim only; schema accepts bare domains or URLs)
  ['website', 'instagram_url', 'facebook_url'].forEach((key) => {
    if (typeof payload[key] === 'string') {
      payload[key] = payload[key].trim();
      if (payload[key] === '') {
        payload[key] = null;
      }
    }
  });

  // Normalize address fields (trim and convert empty strings to null)
  ['addressLine1', 'street', 'city', 'state'].forEach((key) => {
    if (typeof payload[key] === 'string') {
      payload[key] = payload[key].trim();
      if (payload[key] === '') {
        payload[key] = null;
      }
    }
  });

  // Coerce postalCode number to string (schema validates digits; model field is String)
  if (typeof payload.postalCode === 'number') {
    payload.postalCode = String(payload.postalCode);
  } else if (typeof payload.postalCode === 'string') {
    payload.postalCode = payload.postalCode.trim();
    if (payload.postalCode === '') {
      payload.postalCode = null;
    }
  }

  // Handle subscriptionEndDate: allow empty/null or coerce invalid strings to null
  if (payload.subscriptionEndDate !== undefined) {
    const value = payload.subscriptionEndDate;
    if (value === '' || value === null || value === 'string') {
      payload.subscriptionEndDate = null;
    } else if (typeof value === 'string' || value instanceof Date) {
      const timestamp = Date.parse(value);
      payload.subscriptionEndDate = isNaN(timestamp)
        ? null
        : new Date(timestamp);
    }
  }

  // Handle subscriptionType: convert number to string enum
  if (typeof payload.subscriptionType === 'number') {
    const { SubscriptionEnumMapping } = require('../utils/CommonEnumValues');
    payload.subscriptionType = SubscriptionEnumMapping[payload.subscriptionType] || SubscriptionEnumMapping[0];
  }

  // Handle setupComplete: ensure it's a boolean
  if (payload.setupComplete !== undefined) {
    payload.setupComplete = Boolean(payload.setupComplete);
  }

  const shop = await updateShopService(req.params.id, payload);
  if (!shop) {
    throw new CustomError('Shop not found', 404);
  }
  res.status(200).json({
    success: true,
    message: 'Shop updated successfully',
    data: shop,
  });
});

const deleteShop = asyncHandler(async (req, res) => {
  const shop = await deleteShopService(req.params.id);
  if (!shop) {
    throw new CustomError('Shop not found', 404);
  }
  res.status(200).json({
    success: true,
    message: 'Shop deleted successfully',
    data: shop,
  });
});

module.exports = { createShop, getShops, getShopById, updateShop, deleteShop };
