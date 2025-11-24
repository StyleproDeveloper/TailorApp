const mongoose = require('mongoose');
const User = require('./src/models/UserModel');
const Role = require('./src/models/RoleModel');

const mobileNumber = '9731033833';

mongoose.connect('mongodb://localhost:27017/tailorapp').then(async () => {
  try {
    console.log('🔍 Checking permissions for user:', mobileNumber);
    
    const user = await User.findOne({ mobile: mobileNumber });
    if (!user) {
      console.log('❌ User not found with mobile:', mobileNumber);
      process.exit(1);
    }
    
    console.log('\n✅ User found:');
    console.log('  - Mobile:', user.mobile);
    console.log('  - Name:', user.name);
    console.log('  - RoleId:', user.roleId);
    console.log('  - ShopId:', user.shopId);
    
    if (!user.shopId || !user.roleId) {
      console.log('\n❌ User missing shopId or roleId');
      process.exit(1);
    }
    
    const roleCollection = `role_${user.shopId}`;
    console.log('\n🔍 Looking for role in collection:', roleCollection);
    
    const RoleModel = mongoose.model(roleCollection, Role.schema, roleCollection);
    const role = await RoleModel.findOne({ roleId: user.roleId });
    
    if (!role) {
      console.log('\n❌ Role not found!');
      console.log('  - RoleId:', user.roleId);
      console.log('  - Collection:', roleCollection);
      console.log('\n📋 Available roles in collection:');
      const allRoles = await RoleModel.find({});
      allRoles.forEach(r => {
        console.log(`  - RoleId: ${r.roleId}, Name: ${r.name}`);
      });
      process.exit(1);
    }
    
    console.log('\n✅ Role found:');
    console.log('  - Name:', role.name);
    console.log('  - RoleId:', role.roleId);
    
    const excludeFields = ['_id', 'roleId', 'name', 'owner', 'createdAt', 'updatedAt', '__v'];
    const permissions = {};
    for (const [key, value] of Object.entries(role)) {
      if (!excludeFields.includes(key) && typeof value === 'boolean') {
        permissions[key] = value;
      }
    }
    
    console.log('\n📋 Permissions:');
    console.log(JSON.stringify(permissions, null, 2));
    
    console.log('\n🔍 Key permissions for tabs:');
    console.log('  - viewOrder:', permissions['viewOrder'], '(Order tab)');
    console.log('  - viewCustomer:', permissions['viewCustomer'], '(Customer tab)');
    console.log('  - viewReports:', permissions['viewReports'], '(Reports tab)');
    console.log('  - administration:', permissions['administration'], '(Settings tab)');
    
    console.log('\n📊 Tab visibility:');
    console.log('  - Order tab:', permissions['viewOrder'] ? '✅ VISIBLE' : '❌ HIDDEN');
    console.log('  - Customer tab:', permissions['viewCustomer'] ? '✅ VISIBLE' : '❌ HIDDEN');
    console.log('  - Gallery tab: ✅ ALWAYS VISIBLE');
    console.log('  - Reports tab:', permissions['viewReports'] ? '✅ VISIBLE' : '❌ HIDDEN');
    console.log('  - Settings tab:', permissions['administration'] ? '✅ VISIBLE' : '❌ HIDDEN');
    
    const visibleTabs = [
      permissions['viewOrder'] ? 'Order' : null,
      permissions['viewCustomer'] ? 'Customer' : null,
      'Gallery',
      permissions['viewReports'] ? 'Reports' : null,
      permissions['administration'] ? 'Settings' : null,
    ].filter(Boolean);
    
    console.log('\n📱 Expected visible tabs:', visibleTabs.length);
    console.log('  ', visibleTabs.join(', '));
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
});

