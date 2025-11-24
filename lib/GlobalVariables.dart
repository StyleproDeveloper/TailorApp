import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Services/PermissionService.dart';

class GlobalVariables {
  static int? shopIdGet;
  static int? branchId;
  static int? userId;
  static int? roleId;
  static String? roleName;
  static Map<String, bool> permissions = {};
  static String? subscriptionType;
  static String? trialEndDate;

  static Future<void> loadShopId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    shopIdGet = pref.getInt(Textstring().shopId);
    branchId = pref.getInt(Textstring().branchId);
    userId = pref.getInt(Textstring().userId);
    
    // Load role and permissions
    roleId = await PermissionService.getRoleId();
    roleName = await PermissionService.getRoleName();
    permissions = await PermissionService.loadPermissions();
    
    // Load subscription data from SharedPreferences (if saved)
    subscriptionType = pref.getString('subscriptionType');
    trialEndDate = pref.getString('trialEndDate');
    
    print('🔍 GlobalVariables.loadShopId() - Loaded permissions:');
    print('  - roleId: $roleId');
    print('  - roleName: $roleName');
    print('  - permissions: $permissions');
    print('  - permissions count: ${permissions.length}');
    print('  - subscriptionType: $subscriptionType');
    print('  - trialEndDate: $trialEndDate');
  }
  
  // Method to update subscription data (called after login or when shop data is fetched)
  static Future<void> updateSubscriptionData(String? subType, String? endDate) async {
    subscriptionType = subType;
    trialEndDate = endDate;
    
    // Save to SharedPreferences for persistence
    final pref = await SharedPreferences.getInstance();
    if (subscriptionType != null) {
      await pref.setString('subscriptionType', subscriptionType!);
    } else {
      await pref.remove('subscriptionType');
    }
    if (trialEndDate != null) {
      await pref.setString('trialEndDate', trialEndDate!);
    } else {
      await pref.remove('trialEndDate');
    }
    
    print('✅ Updated subscription data: subscriptionType=$subscriptionType, trialEndDate=$trialEndDate');
  }

  // Helper method to check permissions
  static bool hasPermission(String permission) {
    final result = permissions[permission] == true; // Explicitly check for true
    print('🔍 GlobalVariables.hasPermission("$permission") = $result');
    print('🔍 Current permissions map: $permissions');
    print('🔍 permissions.isEmpty: ${permissions.isEmpty}');
    return result;
  }

  // Helper method to check multiple permissions (ALL required)
  static bool hasAllPermissions(List<String> permissionList) {
    for (var permission in permissionList) {
      if (permissions[permission] != true) {
        return false;
      }
    }
    return true;
  }

  // Helper method to check multiple permissions (ANY required)
  static bool hasAnyPermission(List<String> permissionList) {
    for (var permission in permissionList) {
      if (permissions[permission] == true) {
        return true;
      }
    }
    return false;
  }
}