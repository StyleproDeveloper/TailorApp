const {
  createShopService,
  getShopsService,
  getShopByIdService,
  updateShopService,
  deleteShopService,
} = require('../service/ShopService');

const createShop = async (req, res) => {
  try {
    const shop = await createShopService(req.body);
    res.status(201).json({ message: 'Shop created successfully', shop });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getShops = async (req, res) => {
  try {
    const shops = await getShopsService(req?.query);
    res.status(200).json(shops);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getShopById = async (req, res) => {
  try {
    const shop = await getShopByIdService(req.params.id);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    res.status(200).json(shop);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const updateShop = async (req, res) => {
  try {
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

    // Coerce postalCode number to string (schema validates digits; model field is String)
    if (typeof payload.postalCode === 'number') {
      payload.postalCode = String(payload.postalCode);
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
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    res.status(200).json({ message: 'Shop updated successfully', shop });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteShop = async (req, res) => {
  try {
    const shop = await deleteShopService(req.params.id);
    res.status(200).json({ message: 'Shop deleted successfully', shop });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { createShop, getShops, getShopById, updateShop, deleteShop };
