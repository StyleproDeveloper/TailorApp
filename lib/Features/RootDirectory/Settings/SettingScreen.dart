import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Routes/App_route.dart';
import '../../../Core/Widgets/CommonHeader.dart';
import '../../../Core/Widgets/CustomConfirmationDialog.dart';
import '../../../GlobalVariables.dart';
import '../../../Core/Services/PermissionService.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Map<String, dynamic>> _settingsOptions = [
    {'title': 'User', 'icon': Icons.person, 'route': AppRoutes.userScreen},
    {'title': 'Roles', 'icon': Icons.vpn_key, 'route': AppRoutes.roleScreen},
    {
      'title': 'Expense',
      'icon': Icons.account_balance_wallet,
      'route': AppRoutes.expenses
    },
    {'title': 'Dress', 'icon': Icons.checkroom, 'route': AppRoutes.dressScreen},
    // {'title': 'Billing Terms', 'icon': Icons.description, 'route': AppRoutes.billingTerms},
    {
      'title': 'Billing Terms',
      'icon': Icons.note_add_outlined,
      'route': AppRoutes.billingTermsScreen
    },
    {
      'title': 'Shop & Branches',
      'icon': Icons.store,
      'route': AppRoutes.shopBranches
    },
    {
      'title': 'Contact Support',
      'icon': Icons.contact_support,
      'route': AppRoutes.contactSupportScreen
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has administration permission
    final hasAdminPermission = GlobalVariables.hasPermission('administration');
    
    // Filter settings options based on permission
    final visibleSettingsOptions = hasAdminPermission 
        ? _settingsOptions 
        : <Map<String, dynamic>>[]; // Show no settings options if no admin permission
    
    return Scaffold(
      appBar: Commonheader(
        title: Textstring().settings,
        titleSpacing: 20,
        showBackArrow: false,
      ),
      backgroundColor: ColorPalatte.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Column(
          children: [
            // Settings options (only if user has admin permission)
            if (hasAdminPermission)
              Expanded(
                child: ListView.builder(
                  itemCount: visibleSettingsOptions.length,
                  itemBuilder: (context, index) {
                    final item = visibleSettingsOptions[index];
                    return _buildSettingsTile(
                      title: item['title'],
                      icon: item['icon'],
                      onTap: () => Navigator.of(context).pushNamed(item['route']),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You do not have permission to access settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Logout button - always visible at the bottom for all roles
            _buildLogoutTile(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
          leading: CircleAvatar(
            backgroundColor: ColorPalatte.borderGray,
            child: Icon(icon, color: ColorPalatte.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontFamily: Fonts.Regular,
                color: ColorPalatte.black),
          ),
          trailing:
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        ),
        Divider(
          thickness: 1,
          color: ColorPalatte.borderGray,
          height: 0,
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmationDialog(
        title: "Log out?",
        message: "Are you sure you want to log out?",
        cancelText: "Cancel",
        confirmText: "Log Out",
        cancelColor: ColorPalatte.white,
        confirmColor: ColorPalatte.primary,
        onCancel: () {
          print('object cancel');
        },
        onConfirm: () async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          
          // Clear permissions before clearing all preferences
          await PermissionService.clearPermissions();
          await pref.clear();

          // Use pushNamedAndRemoveUntil if using named routes
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        onTap: () {
          _showLogoutDialog(context);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 24),
        ),
        title: const Text(
          "Logout",
          style: TextStyle(
            fontSize: 18,
            fontFamily: Fonts.Regular,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.red),
      ),
    );
  }
}
