const paginate = async (model, query = {}, extension = {}) => {
  const {
    aggregate = null,
    page = 1,
    sortBy = {}, // Default sorting
    limit = 10,
    select = null, // Change default to null
    searchKeyword = '',
    searchBy = [],
  } = extension;

  try {
    // Apply common search across multiple fields
    // if (searchKeyword && searchBy.length > 0) {
    //   query['$or'] = searchBy.map((field) => ({
    //     [field]: { $regex: searchKeyword, $options: 'i' },
    //   }));
    // }

    const count = await model.countDocuments(query);

    let result;

    if (aggregate) {
      const pipeline = [
        { $match: query },
        ...aggregate,
        { $sort: sortBy },
        { $skip: (page - 1) * limit },
        { $limit: limit },
      ];

      // Only add $project if select is specified
      if (select && Object.keys(select).length > 0) {
        pipeline.push({ $project: select });
      }

      result = await model.aggregate(pipeline);
    } else {
      let queryBuilder = model
        .find(query)
        .sort(sortBy)
        .skip((page - 1) * limit)
        .limit(limit);

      if (select && Object.keys(select).length > 0) {
        queryBuilder = queryBuilder.select(select);
      }

      result = await queryBuilder.exec();
    }

    return {
      total: count,
      pageSize: limit,
      pageNumber: page,
      data: result,
    };
  } catch (error) {
    throw error;
  }
};

module.exports = { paginate };
