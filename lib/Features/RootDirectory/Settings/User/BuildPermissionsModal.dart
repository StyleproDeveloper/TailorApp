import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/User/UserStyles.dart';

class BuildPermission extends StatefulWidget {
  final String? selectedRole;

  BuildPermission({required this.selectedRole});

  @override
  _BuildPermissionState createState() => _BuildPermissionState();
}

class _BuildPermissionState extends State<BuildPermission> {
  late String? _selectedRole;
  
  List<String> roles = [
    'Owner',
    'Shop Manager',
    'Staff',
    'Worker',
    'Cutting Master',
    'Tailor'
  ];

  Map<String, bool> permissions = {
    "View Order": true,
    "Web Access": false,
    "Assign Dress Item": false,
    "Add New Order": false,
    "View Prices": false,
    "View Customers": false,
    "Edit Order": false,
    "Edit Shop": false,
    "View Gallery Tab": true,
    "View Reports Tab": false,
    "Add/Edit Payments": false,
    "Edit Folder and Add Images": false,
    "Manage Tasks": false,
    "Administration": false,
    "Manage Workshop": false,
  };

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole ?? "Owner";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 1.1,
        child: Material(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: ColorPalatte.black,),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                // Dropdown for Role Selection
                DropdownButtonFormField<String>(
                  style: Userstyles.fullnameLable,
                  decoration: InputDecoration(
                    labelText: "Select Role",
                    labelStyle: Userstyles.fullnameLable,
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedRole,
                  items: roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // Permissions Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: ColorPalatte.primary,
                  child: Text(
                    Textstring().permission,
                    style: Userstyles.permission
                    ),
                ),

                // Scrollable Permissions List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: permissions.keys.map((permission) {
                        bool isAllowed = permissions[permission] ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(permission, style: Userstyles.listPermissions,),
                                Icon(
                                  isAllowed ? Icons.check : Icons.close,
                                  color: isAllowed ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
