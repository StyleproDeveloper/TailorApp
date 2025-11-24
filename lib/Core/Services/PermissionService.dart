import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tailorapp/Core/Constants/TextString.dart';

class PermissionService {
  static const String _permissionsKey = 'rolePermissions';
  static const String _roleIdKey = 'roleId';
  static const String _roleNameKey = 'roleName';

  // Save permissions after login
  static Future<void> savePermissions({
    required int roleId,
    required String? roleName,
    required Map<String, dynamic> permissions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roleIdKey, roleId);
    if (roleName != null) {
      await prefs.setString(_roleNameKey, roleName);
    }
    final permissionsJson = jsonEncode(permissions);
    await prefs.setString(_permissionsKey, permissionsJson);
    print('🔍 PermissionService.savePermissions - Saved:');
    print('  - roleId: $roleId');
    print('  - roleName: $roleName');
    print('  - permissions JSON: $permissionsJson');
    print('  - permissions count: ${permissions.length}');
  }

  // Load permissions
  static Future<Map<String, bool>> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsJson = prefs.getString(_permissionsKey);
    print('🔍 PermissionService.loadPermissions - Loading:');
    print('  - permissionsJson exists: ${permissionsJson != null}');
    if (permissionsJson != null) {
      print('  - permissionsJson: $permissionsJson');
      try {
        final Map<String, dynamic> decoded = jsonDecode(permissionsJson);
        final result = decoded.map((key, value) => MapEntry(key, value as bool));
        print('  - Loaded ${result.length} permissions: $result');
        return result;
      } catch (e) {
        print('❌ Error loading permissions: $e');
        return {};
      }
    }
    print('  - No permissions found in SharedPreferences');
    return {};
  }

  // Get role ID
  static Future<int?> getRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_roleIdKey);
  }

  // Get role name
  static Future<String?> getRoleName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleNameKey);
  }

  // Check if user has a specific permission
  static Future<bool> hasPermission(String permission) async {
    final permissions = await loadPermissions();
    final result = permissions[permission] == true; // Explicitly check for true
    print('🔍 PermissionService.hasPermission("$permission") = $result');
    print('🔍 All permissions: $permissions');
    return result;
  }

  // Check multiple permissions (returns true if ALL are granted)
  static Future<bool> hasAllPermissions(List<String> permissionList) async {
    final permissions = await loadPermissions();
    for (var permission in permissionList) {
      if (permissions[permission] != true) {
        return false;
      }
    }
    return true;
  }

  // Check multiple permissions (returns true if ANY is granted)
  static Future<bool> hasAnyPermission(List<String> permissionList) async {
    final permissions = await loadPermissions();
    for (var permission in permissionList) {
      if (permissions[permission] == true) {
        return true;
      }
    }
    return false;
  }

  // Clear permissions (on logout)
  static Future<void> clearPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
    await prefs.remove(_roleIdKey);
    await prefs.remove(_roleNameKey);
  }

  // Get all permissions as a map
  static Future<Map<String, bool>> getAllPermissions() async {
    return await loadPermissions();
  }
}

