const StitchingTypes = [
  {
    value: 1,
    label: 'Stitching',
  },
  {
    value: 2,
    label: 'Alteration',
  },
  {
    value: 3,
    label: 'Material',
  },
];


// Define ENUM values
const SubscriptionEnum = {
  TRIAL: "Trial",
  PAID_MONTHLY: "Paid-monthly",
  PAID_YEARLY: "Paid-yearly",
};

// Define ENUM mapping for numbers (Optional)
const SubscriptionEnumMapping = {
  0: SubscriptionEnum.TRIAL,
  1: SubscriptionEnum.PAID_MONTHLY,
  2: SubscriptionEnum.PAID_YEARLY,
};

module.exports = { StitchingTypes, SubscriptionEnum, SubscriptionEnumMapping };
