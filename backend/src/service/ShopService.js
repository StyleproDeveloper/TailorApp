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
const GallerySchema = require('../models/GalleryModel').schema;
const RoleSchema = require('../models/RoleModel').schema;
const { getDynamicModel } = require('../utils/DynamicModel');
const { getNextSequenceValue } = require('./sequenceService');
const { SubscriptionEnum, SubscriptionEnumMapping } = require('../utils/CommonEnumValues');
const { buildQueryOptions } = require('../utils/buildQuery');
const { paginate } = require('../utils/commonPagination');
const { createUserService } = require('./UserService');
const { getRoleModel } = require('./RoleService');
const { createShopBucket, configureBucketCors, configureBucketPublicReadPolicy, configurePublicAccessBlock } = require('../utils/s3Service');
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

    // Always set subscriptionType to TRIAL for new shops
    let subscriptionType = SubscriptionEnum.TRIAL;
    
    // Calculate trial dates (30 days from creation)
    const trialStartDate = new Date();
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 30); // Add 30 days
    
    logger.debug('Default roles initialized', { count: defaultRoles.length });
    logger.info('Setting up trial period', {
      shopId,
      trialStartDate: trialStartDate.toISOString(),
      trialEndDate: trialEndDate.toISOString(),
    });

    // Ensure all address fields are properly set and preserved
    // Handle both string and already-trimmed values
    const normalizeAddressField = (value) => {
      if (value === null || value === undefined) return null;
      const strValue = String(value).trim();
      return strValue !== '' ? strValue : null;
    };

    const shopDataToSave = {
      ...shopData,
      shop_id: shopId,
      subscriptionType: SubscriptionEnum.TRIAL, // Always set to TRIAL for new shops
      trialStartDate, // Set trial start date
      trialEndDate, // Set trial end date (30 days from start)
      active: shopData.active !== undefined ? shopData.active : true, // Default to true on registration
      // Explicitly set address fields to ensure they're saved (preserve values even if empty strings)
      addressLine1: normalizeAddressField(shopData.addressLine1),
      street: normalizeAddressField(shopData.street),
      city: normalizeAddressField(shopData.city),
      state: normalizeAddressField(shopData.state),
      postalCode: shopData.postalCode ? String(shopData.postalCode).trim() : null,
    };

    logger.debug('Creating shop with data', {
      shopId,
      addressLine1: shopDataToSave.addressLine1,
      street: shopDataToSave.street,
      city: shopDataToSave.city,
      state: shopDataToSave.state,
      postalCode: shopDataToSave.postalCode,
    });

    const newShop = new ShopInfo(shopDataToSave);

    // Dynamically initialize  collections based on shopId
    const initializeCollections = async () => {
      const db = mongoose.connection.db;
      
      // Helper function to copy data from master collection to shop-specific collection
      const copyMasterData = async (masterCollectionName, targetModel, shopId, dataType, fieldMapper = null) => {
        try {
          const masterData = await db.collection(masterCollectionName).find({}).toArray();
          
          if (masterData && masterData.length > 0) {
            logger.info(`Found ${masterData.length} ${dataType} in ${masterCollectionName} to copy`, { shopId });
            
            // Map documents - apply field mapper if provided, otherwise use direct copy
            const documentsToInsert = await Promise.all(masterData.map(async (doc, index) => {
              const { _id, ...rest } = doc;
              
              // Apply field mapping if provided
              if (fieldMapper && typeof fieldMapper === 'function') {
                const mapped = await fieldMapper(rest, index);
                return mapped;
              }
              
              return rest;
            }));
            
            // Filter out documents with null required fields (dressTypeId, measurementId, etc.)
            const validDocuments = documentsToInsert.filter(doc => {
              // For dressTypeMeasurement, ensure dressTypeId and measurementId are not null
              if (dataType === 'dress type measurements') {
                return doc.dressTypeId != null && doc.measurementId != null && doc.name != null && doc.name !== '';
              }
              // For other types, just check that the document is not empty
              return doc && Object.keys(doc).length > 0;
            });
            
            if (validDocuments.length > 0) {
              // Check if collection already has data to avoid duplicates
              const existingCount = await targetModel.countDocuments();
              if (existingCount === 0) {
                // Use insertMany with ordered: false to continue inserting even if some fail
                try {
                  const result = await targetModel.insertMany(validDocuments, { ordered: false });
                  logger.info(`Successfully copied ${result.length} ${dataType} from ${masterCollectionName}`, {
                    shopId,
                    totalInMaster: masterData.length,
                    validDocuments: validDocuments.length,
                    inserted: result.length,
                  });
                } catch (insertError) {
                  // If some documents failed, log but continue
                  if (insertError.writeErrors && insertError.writeErrors.length > 0) {
                    const successfulInserts = validDocuments.length - insertError.writeErrors.length;
                    logger.warn(`Partially copied ${dataType}: ${successfulInserts} succeeded, ${insertError.writeErrors.length} failed`, {
                      shopId,
                      errors: insertError.writeErrors.slice(0, 5), // Log first 5 errors
                    });
                  } else {
                    throw insertError;
                  }
                }
              } else {
                logger.info(`Skipping copy of ${dataType} - collection already has ${existingCount} documents`, { shopId });
              }
            } else {
              logger.warn(`No valid ${dataType} documents to insert after filtering`, {
                shopId,
                totalInMaster: masterData.length,
                mapped: documentsToInsert.length,
              });
            }
          } else {
            logger.warn(`No ${dataType} found in ${masterCollectionName} collection`, { shopId });
          }
        } catch (copyError) {
          logger.error(`Error copying ${dataType} from ${masterCollectionName}`, copyError, {
            shopId,
            errorMessage: copyError.message,
            errorStack: copyError.stack,
          });
          // Continue even if copy fails - collection is still created
        }
      };

      // Create dressType collection and copy from masterdresstype
      const dressTypeModel = await getDynamicModel('DressType', DressTypeSchema, `dressType_${shopId}`);
      await copyMasterData('masterdresstype', dressTypeModel, shopId, 'dress types');
      
      // Create measurement collection and copy from mastermeasurements
      const measurementModel = await getDynamicModel(
        'Measurements',
        MeasurementSchema,
        `measurement_${shopId}`
      );
      await copyMasterData('mastermeasurements', measurementModel, shopId, 'measurements');
      
      // Create dresspattern collection and copy from masterdresspatterns
      const dressPatternModel = await getDynamicModel(
        'Dresspattern',
        DressPatternSchema,
        `dresspattern_${shopId}`
      );
      await copyMasterData('masterdresspatterns', dressPatternModel, shopId, 'dress patterns');
      
      // Create dressTypeMeasurement collection and copy from masterdresstypemeasurements
      const dressTypeMeasurementModel = await getDynamicModel(
        'DressTypeMeasurement',
        DressTypeMeasurementSchema,
        `dressTypeMeasurement_${shopId}`
      );
      // Map old field names to new schema field names
      await copyMasterData('masterdresstypemeasurements', dressTypeMeasurementModel, shopId, 'dress type measurements', (doc) => {
        // Map old format (DressType_ID, Measurement_ID, Measurement) to new format (dressTypeId, measurementId, name)
        return {
          dressTypeId: doc.DressType_ID ?? doc.dressTypeId ?? null,
          measurementId: doc.Measurement_ID ?? doc.measurementId ?? null,
          name: doc.Measurement ?? doc.name ?? '',
          dressTypeMeasurementId: doc.dressTypeMeasurementId ?? null, // Will be auto-generated if null
          owner: doc.owner ?? null,
        };
      });
      
      // Create dressTypeDressPattern collection and copy from masterdresstypedresspattern
      const dressTypeDressPatternModel = await getDynamicModel(
        'DressTypeDressPattern',
        DressTypeDresspatternSchema,
        `dressTypeDressPattern_${shopId}`
      );
      // Copy from masterdresstypedresspattern to shop-specific collection
      await copyMasterData('masterdresstypedresspattern', dressTypeDressPatternModel, shopId, 'dress type dress patterns', async (doc, index) => {
        // Map old format to new format if needed
        // dressTypePatternId is required, so we'll generate it if missing
        let dressTypePatternId = doc.dressTypePatternId ?? doc.Id ?? null;
        if (!dressTypePatternId) {
          // Generate a unique ID if missing (using index + timestamp as fallback)
          dressTypePatternId = Date.now() + index;
        }
        
        return {
          dressTypeId: doc.DressType_ID ?? doc.dressTypeId ?? null,
          dressPatternId: doc.DressPattern_ID ?? doc.dressPatternId ?? null,
          dressTypePatternId: dressTypePatternId,
          category: doc.category ?? doc.Category ?? null,
          owner: doc.owner ?? null,
        };
      });
      
      // Create other collections (no master data to copy)
      await getDynamicModel('Customer', CustomerSchema, `customer_${shopId}`);
      await getDynamicModel(
        'MeasurementHistory',
        MeasurementHistorySchema,
        `measurementHistory_${shopId}`
      );
      await getDynamicModel('OrderItem', OrderItemSchema, `orderItem_${shopId}`);
      await getDynamicModel('Order', OrderSchema, `order_${shopId}`);
      await getDynamicModel('OrderItemAdditionalCost', OrderItemAdditionalCostSchema, `orderitemadditionalcost_${shopId}`);
      await getDynamicModel('OrderMedia', OrderMediaSchema, `ordermedia_${shopId}`);
      await getDynamicModel('Gallery', GallerySchema, `gallery_${shopId}`);
      // Await Role creation to ensure roles are saved before user creation
      await getDynamicModel('Role', RoleSchema, `role_${shopId}`, defaultRoles);
    };

    await initializeCollections();

    const savedShop = await newShop.save();
    
    // Log saved shop data to verify all fields are saved
    logger.debug('Shop saved successfully', {
      shopId: savedShop.shop_id,
      addressLine1: savedShop.addressLine1,
      street: savedShop.street,
      city: savedShop.city,
      state: savedShop.state,
      postalCode: savedShop.postalCode,
    });

    // Create S3 bucket for the shop
    try {
      const bucketName = await createShopBucket(shopData.shopName || shopData.yourName, shopId);
      
      // Update shop with bucket name
      savedShop.s3BucketName = bucketName;
      await savedShop.save();
      
      logger.info('S3 bucket created and saved to shop', { shopId, bucketName });
    } catch (s3Error) {
      // Log error but don't fail shop creation if S3 bucket creation fails
      logger.error('Error creating S3 bucket for shop', s3Error, { shopId });
      // Continue - shop is already created, S3 bucket can be created later
    }

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

const configureShopBucketCorsService = async (shopId) => {
  try {
    const shop = await ShopInfo.findOne({ shop_id: Number(shopId) });
    if (!shop) {
      throw new Error(`Shop with ID ${shopId} not found`);
    }

    if (!shop.s3BucketName) {
      throw new Error(`Shop ${shopId} does not have an S3 bucket configured`);
    }

    // Configure public access block
    try {
      await configurePublicAccessBlock(shop.s3BucketName);
      logger.info('Public access block configured for shop bucket', { shopId, bucketName: shop.s3BucketName });
    } catch (error) {
      logger.warn('Failed to configure public access block (non-critical)', { shopId, error: error.message });
    }

    // Configure bucket policy for public read
    try {
      await configureBucketPublicReadPolicy(shop.s3BucketName);
      logger.info('Public read policy configured for shop bucket', { shopId, bucketName: shop.s3BucketName });
    } catch (error) {
      logger.warn('Failed to configure bucket policy (non-critical)', { shopId, error: error.message });
    }

    // Configure CORS
    await configureBucketCors(shop.s3BucketName);
    logger.info('CORS configured for shop bucket', { shopId, bucketName: shop.s3BucketName });

    return {
      success: true,
      message: 'Bucket permissions configured successfully (CORS, public access, and public read policy)',
      bucketName: shop.s3BucketName,
    };
  } catch (error) {
    logger.error('Error configuring bucket permissions', error, { shopId });
    throw error;
  }
};

module.exports = {
  createShopService,
  getShopsService,
  getShopByIdService,
  updateShopService,
  deleteShopService,
  configureShopBucketCorsService,
};
