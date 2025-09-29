const { getDefaultSort } = require('./defaultSorting');

const buildQueryOptions = (
  queryParams,
  defaultSortField = 'createdAt', // Default sorting field
  searchableFields = [],
  numericFields = [] // Specify numeric fields like roleId
) => {
  const parseBoolean = (value) => {
    if (typeof value === 'string') {
      if (value.toLowerCase() === 'true') return true;
      if (value.toLowerCase() === 'false') return false;
    }
    return undefined; // Ignore invalid values like "i"
  };

  const dateFields = ['gst_reg_date'];

  const booleanFields = [
    'viewOrder',
    'editOrder',
    'createOrder',
    'viewPrice',
    'viewShop',
    'editShop',
    'viewCustomer',
    'editCustomer',
    'administration',
    'viewReports',
    'addDressItem',
    'payments',
    'viewAllBranches',
    'assignDressItem',
    'manageOrderStatus',
    'manageWorkShop',
    'gst_available',
    'notificationOptIn',
    'gst',
  ];

  // Common search across multiple fields (handling numbers separately)
  // let searchQuery = {};
  // if (queryParams.searchKeyword && searchableFields.length > 0) {
  //   searchQuery['$or'] = searchableFields
  //     .filter((field) => !numericFields.includes(field)) // Exclude number fields from $regex
  //     .map((field) => ({
  //       [field]: { $regex: queryParams.searchKeyword, $options: 'i' },
  //     }));

  //   // If the keyword is a valid number, add direct matches for numeric fields
  //   if (!isNaN(queryParams.searchKeyword)) {
  //     numericFields.forEach((field) => {
  //       searchQuery['$or'].push({ [field]: Number(queryParams.searchKeyword) });
  //     });
  //   }
  // }

  let searchQuery = {};
  const searchKeyword = queryParams?.searchKeyword || '';

  if (queryParams?.searchKeyword && searchableFields?.length > 0) {
    searchQuery['$or'] = searchableFields?.map((field) => ({
      [field]: { $regex: searchKeyword, $options: 'i' },
    }));
  }

  return {
    page: parseInt(queryParams.pageNumber) || 1,
    limit: parseInt(queryParams.pageSize) || 10,
    sortBy: getDefaultSort(
      queryParams.sortBy,
      queryParams.sortDirection,
      defaultSortField
    ),
    search: searchQuery,
    booleanFilters: Object.keys(queryParams)
      .filter((key) => booleanFields.includes(key))
      .reduce((acc, key) => {
        const boolValue = parseBoolean(queryParams[key], key); // Pass key for error message
        acc[key] = boolValue;
        return acc;
      }, {}),
  };
};

module.exports = { buildQueryOptions };
