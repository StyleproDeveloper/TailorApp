const getDefaultSort = (sortBy, sortDirection, defaultSortField) => {
  if (sortBy) {
    return { [sortBy]: sortDirection === 'asc' ? 1 : -1 };
  }
  return { [defaultSortField]: 1 }; // Default ascending order
};

module.exports = { getDefaultSort };
