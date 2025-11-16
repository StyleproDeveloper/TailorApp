// Test script to verify trial expiration API response
require('dotenv').config({ path: './backend/.env' });
const axios = require('axios');

const BASE_URL = 'http://localhost:5500';

async function testTrialExpiration() {
  try {
    // Step 1: Login (get OTP)
    console.log('📱 Step 1: Requesting OTP...');
    const mobileNumber = '+915656565656'; // User from shop 87 (zoom tailors)
    
    const loginResponse = await axios.post(`${BASE_URL}/auth/login`, {
      mobileNumber: mobileNumber
    });
    
    console.log('✅ OTP sent:', loginResponse.data.otp);
    const otp = loginResponse.data.otp;
    
    // Step 2: Validate OTP
    console.log('\n📱 Step 2: Validating OTP...');
    const validateResponse = await axios.post(`${BASE_URL}/auth/validate-otp`, {
      mobileNumber: mobileNumber,
      otp: otp
    });
    
    console.log('\n📊 Full Response:');
    console.log(JSON.stringify(validateResponse.data, null, 2));
    
    console.log('\n🔍 Subscription Status Check:');
    const subscriptionStatus = validateResponse.data.subscriptionStatus;
    if (subscriptionStatus) {
      console.log('  ✅ subscriptionStatus exists');
      console.log('  Subscription Type:', subscriptionStatus.subscriptionType);
      console.log('  Is Trial Expired:', subscriptionStatus.isTrialExpired);
      console.log('  Trial End Date:', subscriptionStatus.trialEndDate);
      console.log('  Requires Subscription:', subscriptionStatus.requiresSubscription);
      
      if (subscriptionStatus.requiresSubscription) {
        console.log('\n✅ Should redirect to subscribe page!');
      } else {
        console.log('\n⚠️  Should NOT redirect to subscribe page');
      }
    } else {
      console.log('  ❌ subscriptionStatus is MISSING from response!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testTrialExpiration();

