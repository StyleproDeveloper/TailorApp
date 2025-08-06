import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Tools/Helper.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Roles/RoleStyle.dart';
import '../../../../Core/Services/Services.dart';
import '../../../../Core/Services/Urls.dart';
import '../../../../Core/Widgets/CustomLoader.dart';
import '../../../../GlobalVariables.dart';

class AddRoleModal extends StatefulWidget {
  const AddRoleModal({super.key, required this.onClose, this.userData, this.submit});
  final Map<String, dynamic>? userData;

  final VoidCallback onClose;
  final VoidCallback? submit;

  @override
  _AddRoleModalState createState() => _AddRoleModalState();
}

class _AddRoleModalState extends State<AddRoleModal> {
  final TextEditingController roleNameController = TextEditingController();

  final Map<String, bool> permissions = {
    'View Order': false,
    'Edit Order': false,
    'Create Order': false,
    'View Price': false,
    'View Shop': false,
    'Edit Shop': false,
    'View Customer': false,
    'Edit Customer': false,
    'Administration': false,
    'View Reports': false,
    'Add Dress Item': false,
    'Payments': false,
    'View All Branches': false,
    'Assign Dress Item': false,
    'Manage Order Status': false,
    'Manage Workshop': false,
  };

  @override
  void initState() {
    super.initState();

    if (widget.userData != null) {
      roleNameController.text = widget.userData!['name']?.trim() ?? '';

      // Define mapping from API keys to UI keys
      Map<String, String> apiKeyToLocalKey = {
        'viewOrder': 'View Order',
        'editOrder': 'Edit Order',
        'createOrder': 'Create Order',
        'viewPrice': 'View Price',
        'viewShop': 'View Shop',
        'editShop': 'Edit Shop',
        'viewCustomer': 'View Customer',
        'editCustomer': 'Edit Customer',
        'administration': 'Administration',
        'viewReports': 'View Reports',
        'addDressItem': 'Add Dress Item',
        'payments': 'Payments',
        'viewAllBranches': 'View All Branches',
        'assignDressItem': 'Assign Dress Item',
        'manageOrderStatus': 'Manage Order Status',
        'manageWorkShop': 'Manage Workshop',
      };

      // Update permissions based on API response
      widget.userData!.forEach((apiKey, value) {
        if (apiKeyToLocalKey.containsKey(apiKey) && value is bool) {
          String localKey = apiKeyToLocalKey[apiKey]!;
          permissions[localKey] = value;
        }
      });

      // Ensure UI updates after setting permissions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  void handleSaveRole() async {
    int? id = GlobalVariables.shopIdGet;
    int? roleId = widget.userData?['roleId'];

    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Show ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    if (roleNameController.text.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        'Role name is required',
        duration: const Duration(seconds: 1),
      );
      return;
    }

    try {
      showLoader(context);
      final payload = {
        'shop_id': id,
        'name': capitalize(roleNameController.text),
        'owner': 'test', // If needed
        'viewOrder': permissions['View Order'] ?? false,
        'editOrder': permissions['Edit Order'] ?? false,
        'createOrder': permissions['Create Order'] ?? false,
        'viewPrice': permissions['View Price'] ?? false,
        'viewShop': permissions['View Shop'] ?? false,
        'editShop': permissions['Edit Shop'] ?? false,
        'viewCustomer': permissions['View Customer'] ?? false,
        'editCustomer': permissions['Edit Customer'] ?? false,
        'administration': permissions['Administration'] ?? false,
        'viewReports': permissions['View Reports'] ?? false,
        'addDressItem': permissions['Add Dress Item'] ?? false,
        'payments': permissions['Payments'] ?? false,
        'viewAllBranches': permissions['View All Branches'] ?? false,
        'assignDressItem': permissions['Assign Dress Item'] ?? false,
        'manageOrderStatus': permissions['Manage Order Status'] ?? false,
        'manageWorkShop': permissions['Manage Workshop'] ?? false,
      };

      Response response;
      if (widget.userData != null) {
        final requestUrl = "${Urls.addRole}/$id/$roleId";
        response = await ApiService().put(requestUrl, data: payload, context);
      } else {
        response =
            await ApiService().post(Urls.addRole, data: payload, context);
      }
      hideLoader(context);
      if (response.data != null && response.data['message'] != null) {
        CustomSnackbar.showSnackbar(context, response.data['message'],
            duration: Duration(seconds: 1));
        widget.onClose();
        widget.submit!();
      } else {
        CustomSnackbar.showSnackbar(context, 'Error: ${response.statusCode}',
            duration: Duration(seconds: 2));
      }
    } catch (e) {
      hideLoader(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.userData != null ? 'Edit Role' : 'Add Role',
                      style: Rolestyle.headerRole,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                TextField(
                  controller: roleNameController,
                  style: Rolestyle.roleNameLabel,
                  decoration: InputDecoration(
                    labelText: 'Role Name',
                    labelStyle: Rolestyle.roleNameLabel,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: ColorPalatte.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: ColorPalatte.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: permissions.keys.map((String key) {
                    return CheckboxListTile(
                      title: Text(
                        key, // Now showing correct API key
                        style: Rolestyle.roleNameLabel,
                      ),
                      value: permissions[key] ??
                          false, // Ensures a default false value
                      onChanged: (bool? value) {
                        setState(() {
                          permissions[key] = value ?? false;
                        });
                      },
                      checkColor: ColorPalatte.white,
                      activeColor: ColorPalatte.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: handleSaveRole,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalatte.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text(
                        widget.userData != null ? 'Update Role' : 'Save Role',
                        style: Rolestyle.saveBtnRole),
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
