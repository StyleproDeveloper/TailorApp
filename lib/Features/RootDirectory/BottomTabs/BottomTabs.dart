import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Images.dart';
import 'package:tailorapp/Features/RootDirectory/BottomTabs/BottomStyle.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/OrderScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Reports/ReportsScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/SettingScreen.dart';
import 'package:tailorapp/Features/RootDirectory/customer/CustomerScreen.dart';
import 'package:tailorapp/Features/RootDirectory/Gallery/GalleryScreen.dart';
import 'package:tailorapp/Features/RootDirectory/BottomTabs/PermissionDebugWidget.dart';
import 'package:tailorapp/Core/Widgets/TrialBanner.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/GlobalVariables.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _currentIndex = 0;

  // All available pages
  final List<Widget> _allPages = [
    OrderScreen(),
    Customerscreen(),
    GalleryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch shop data after first frame (when context is available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchShopData();
    });
  }

  Future<void> _fetchShopData() async {
    try {
      final shopId = GlobalVariables.shopIdGet;
      if (shopId == null) return;
      
      // Use a dummy context or null - ApiService should handle this
      final response = await ApiService().get('${Urls.shopName}/$shopId', context);
      
      if (response.data != null) {
        final responseData = response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
        final shopData = responseData['data'] ?? responseData;
        
        if (shopData is Map<String, dynamic>) {
          final subType = shopData['subscriptionType']?.toString();
          final trialEnd = shopData['trialEndDate'];
          String? trialEndStr;
          
          if (trialEnd != null) {
            // Handle both Date string and ISO string formats
            if (trialEnd is String) {
              trialEndStr = trialEnd;
            } else {
              trialEndStr = trialEnd.toString();
            }
          }
          
          await GlobalVariables.updateSubscriptionData(subType, trialEndStr);
          
          // Update UI if mounted
          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (e) {
      print('⚠️ Error fetching shop data in BottomTabs: $e');
      // Don't show error - this is not critical
    }
  }

  // Load permissions directly from SharedPreferences
  Future<Map<String, bool>> _loadPermissionsDirectly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsJson = prefs.getString('rolePermissions');
      
      print('🔍🔍🔍 DIRECT PERMISSION CHECK:');
      print('  - permissionsJson exists: ${permissionsJson != null}');
      
      if (permissionsJson != null) {
        print('  - permissionsJson: $permissionsJson');
        try {
          final Map<String, dynamic> decoded = jsonDecode(permissionsJson);
          final permissions = decoded.map((key, value) => MapEntry(key, value as bool));
          print('  - Loaded ${permissions.length} permissions');
          print('  - Permissions: $permissions');
          
          // Log each permission check
          print('  - viewOrder: ${permissions['viewOrder']}');
          print('  - viewCustomer: ${permissions['viewCustomer']}');
          print('  - viewReports: ${permissions['viewReports']}');
          print('  - administration: ${permissions['administration']}');
          
          // Log ALL permissions for debugging
          print('  - ALL PERMISSIONS:');
          permissions.forEach((key, value) {
            print('    $key: $value');
          });
          
          return permissions;
        } catch (e) {
          print('❌ Error parsing permissions: $e');
          return {};
        }
      } else {
        print('❌ No permissions found in SharedPreferences');
        // Also check roleId
        final roleId = prefs.getInt('roleId');
        print('  - roleId: $roleId');
        return {};
      }
    } catch (e) {
      print('❌ Error loading permissions: $e');
      return {};
    }
  }

  // Check if permission exists and is true
  bool _hasPermission(Map<String, bool> permissions, String permission) {
    final value = permissions[permission];
    final result = value == true;
    print('  🔍 Check "$permission": value=$value, result=$result');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL LOG - This MUST appear in console
    print('🚨🚨🚨 BOTTOM TABS BUILD CALLED - NEW CODE IS RUNNING 🚨🚨🚨');
    print('🚨🚨🚨 This log proves the new BottomTabs code is executing 🚨🚨🚨');
    
    return FutureBuilder<Map<String, bool>>(
      future: _loadPermissionsDirectly(),
      builder: (context, snapshot) {
        print('🚨🚨🚨 FUTURE BUILDER CALLBACK - snapshot state: ${snapshot.connectionState} 🚨🚨🚨');
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: ColorPalatte.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorPalatte.primary),
                  SizedBox(height: 16),
                  Text('Loading permissions...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Error loading permissions', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 8),
                  Text('${snapshot.error}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        // Get permissions
        final permissions = snapshot.data ?? {};
        print('🔍🔍🔍 BUILD: Using permissions: $permissions');
        print('🔍🔍🔍 BUILD: Permissions count: ${permissions.length}');

        // Build pages and nav items
        final pages = <Widget>[];
        final navItems = <BottomNavigationBarItem>[];
        int pageIndex = 0;

        // Order tab
        if (_hasPermission(permissions, 'viewOrder')) {
          print('✅ ADDING Order tab');
          pages.add(_allPages[0]);
          navItems.add(
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  Images.orderIcon,
                  color: _currentIndex == pageIndex ? ColorPalatte.primary : Colors.grey,
                ),
              ),
              label: "Order",
            ),
          );
          pageIndex++;
        } else {
          print('❌ SKIPPING Order tab - no viewOrder permission');
        }

        // Customer tab
        if (_hasPermission(permissions, 'viewCustomer')) {
          print('✅ ADDING Customer tab');
          pages.add(_allPages[1]);
          navItems.add(
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  Images.customerIcon,
                  color: _currentIndex == pageIndex ? ColorPalatte.primary : Colors.grey,
                ),
              ),
              label: "Customer",
            ),
          );
          pageIndex++;
        } else {
          print('❌ SKIPPING Customer tab - no viewCustomer permission');
        }

        // Gallery tab - always visible
        print('✅ ADDING Gallery tab (always visible)');
        pages.add(_allPages[2]);
        navItems.add(
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                Images.gallaryIcon,
                color: _currentIndex == pageIndex ? ColorPalatte.primary : Colors.grey,
              ),
            ),
            label: "Gallery",
          ),
        );
        pageIndex++;

        // Reports tab
        if (_hasPermission(permissions, 'viewReports')) {
          print('✅ ADDING Reports tab');
          pages.add(_allPages[3]);
          navItems.add(
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  Images.reportIcon,
                  color: _currentIndex == pageIndex ? ColorPalatte.primary : Colors.grey,
                ),
              ),
              label: "Report",
            ),
          );
          pageIndex++;
        } else {
          print('❌ SKIPPING Reports tab - no viewReports permission');
        }

        // Settings tab - ALWAYS visible for all roles (for logout functionality)
        print('✅ ADDING Settings tab (always visible for logout)');
        pages.add(_allPages[4]);
        navItems.add(
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                Images.settingsIcon,
                color: _currentIndex == pageIndex ? ColorPalatte.primary : Colors.grey,
              ),
            ),
            label: "Settings",
          ),
        );

        print('🔍🔍🔍 FINAL: ${pages.length} pages, ${navItems.length} nav items');

        // If permissions are empty, show diagnostic screen
        if (permissions.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Permission Issue'),
              backgroundColor: Colors.orange,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No Permissions Found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Role-based access is not working because permissions are empty.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PermissionDebugWidget(),
                        ),
                      );
                    },
                    icon: Icon(Icons.bug_report),
                    label: Text('View Debug Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {}); // Refresh
                    },
                    child: Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        // No access (but permissions exist, just no tabs)
        if (pages.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'No access granted',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please contact administrator',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh
                    },
                    child: Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        // Ensure valid index
        final validIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

        return Scaffold(
          backgroundColor: ColorPalatte.white,
          body: Column(
            children: [
              // Trial banner at the top
              TrialBanner(),
              // Main content
              Expanded(
                child: pages[validIndex],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: ColorPalatte.white,
              border: Border(
                top: BorderSide(color: ColorPalatte.borderGray, width: 0.8),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: validIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: ColorPalatte.primary,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              backgroundColor: ColorPalatte.white,
              selectedFontSize: 12,
              selectedLabelStyle: Bottomstyle.bottomText,
              unselectedFontSize: 12,
              unselectedLabelStyle: Bottomstyle.bottomText,
              items: navItems,
            ),
          ),
        );
      },
    );
  }
}
