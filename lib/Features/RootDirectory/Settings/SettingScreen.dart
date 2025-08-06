import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Routes/App_route.dart';
import '../../../Core/Widgets/CommonHeader.dart';
import '../../../Core/Widgets/CustomConfirmationDialog.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Commonheader(
        title: Textstring().settings,
        titleSpacing: 20,
        showBackArrow: false,
      ),
      backgroundColor: ColorPalatte.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: ListView.builder(
          itemCount: _settingsOptions.length + 1, // Extra item for Logout
          itemBuilder: (context, index) {
            if (index == _settingsOptions.length) {
              return _buildLogoutTile(); // Separate logout design
            }
            final item = _settingsOptions[index];
            return _buildSettingsTile(
              title: item['title'],
              icon: item['icon'],
              onTap: () => Navigator.of(context).pushNamed(item['route']),
            );
          },
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
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            _showLogoutDialog(context);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Logout",
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: Fonts.Regular,
                      color: Colors.red,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
        Divider(
          thickness: 1, // Line thickness
          color: ColorPalatte.borderGray, // Light gray color
          height: 0, // No extra spacing
        ),
      ],
    );
  }
}
