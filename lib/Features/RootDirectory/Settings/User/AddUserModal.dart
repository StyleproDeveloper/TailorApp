import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Tools/Helper.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Core/Widgets/Mobile_input_widget.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/User/BuildPermissionsModal.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/User/UserStyles.dart';
import '../../../../GlobalVariables.dart';

class AddUserModal extends StatefulWidget {
  const AddUserModal(
      {super.key, required this.onClose, this.userData, this.sumbit});

  final VoidCallback onClose;
  final VoidCallback? sumbit;
  final Map<String, dynamic>? userData;

  @override
  _AddUserModalState createState() => _AddUserModalState();
}

class _AddUserModalState extends State<AddUserModal> {
  final TextEditingController mobileNum = TextEditingController();
  final TextEditingController fullName = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? _selectedRole;
  List<Map<String, dynamic>> roles = [];
  bool? isLoading = false;
  String? firstTwoDigits;
  String? remainingDigits;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      fullName.text = widget.userData!['name'] ?? '';
      emailController.text = widget.userData!['email'] ?? '';

      // ✅ Store the initial roleId as a String
      _selectedRole = widget.userData!['roleId'].toString();
      final mobileNumber = widget.userData!['phone'].toString();
      firstTwoDigits = mobileNumber.substring(0, 2);
      remainingDigits = mobileNumber.substring(2);
      mobileNum.text = remainingDigits.toString();
    }
    _fetchRoleData();
  }

  Future<void> _fetchRoleData() async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    final String requestUrl = "${Urls.addRole}/$id";
    print('Fetching role data from: $requestUrl');

    try {
      // Future.delayed(Duration.zero, () => showLoader(context));

      final response = await ApiService().get(requestUrl, context);
      print('Role API Response: $response');

      // Future.delayed(Duration.zero, () => hideLoader(context));
      if (!mounted) return;

      if (response.data is Map<String, dynamic> &&
          response.data['data'] is List<dynamic>) {
        List<dynamic> roleData = response.data['data'];
        if (!mounted) return;

        setState(() {
          roles = roleData.map<Map<String, dynamic>>((role) {
            return {
              'name': role['name'] ?? 'Unknown role',
              'roleId': role['roleId'].toString(), // ✅ Ensure roleId is String
            };
          }).toList();

          // ✅ Check if _selectedRole is valid and update it
          if (_selectedRole != null &&
              roles.any((role) => role['roleId'] == _selectedRole)) {
            _selectedRole =
                _selectedRole; // No change needed, but confirmed valid
          } else {
            _selectedRole = null; // If not found, reset selection
          }

          isLoading = false;
        });
      } else {
        Future.microtask(() => CustomSnackbar.showSnackbar(
              context,
              'Roles not found',
              duration: Duration(seconds: 1),
            ));
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Future.delayed(Duration.zero, () => hideLoader(context));
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            'Failed to load roles',
            duration: Duration(seconds: 2),
          ));
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleSaveUser() async {
    if (!mounted) return;

    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    SharedPreferences pref = await SharedPreferences.getInstance();
    int? branchId = pref.getInt(Textstring().branchId);

    if (fullName.text.isEmpty) {
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          Textstring().nameIsRequired,
          duration: const Duration(seconds: 1),
        );
      }
      return;
    }

    if (mobileNum.text.isEmpty) {
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          Textstring().mobileIsRequired,
          duration: const Duration(seconds: 1),
        );
      }
      return;
    }

    if (_selectedRole == null) {
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          Textstring().roleIsRequired,
          duration: const Duration(seconds: 1),
        );
      }
      return;
    }

    try {
      if (mounted) showLoader(context);
      final mobileNumber =
          (firstTwoDigits! + mobileNum.text).replaceAll('+', '');

      final payload = {
        "shopId": shopId,
        "branchId": branchId,
        "mobile": mobileNumber,
        "name": capitalize(fullName.text),
        "roleId": _selectedRole,
        "secondaryMobile": "",
        "email": emailController.text,
        "addressLine1": "",
        "street": "",
        "city": "",
        "postalCode": 0
      };
      Response response;
      if (widget.userData != null) {
        final requestUrl = "${Urls.addUsers}/${widget.userData!['userId']}";
        response = await ApiService().put(requestUrl, data: payload, context);
      } else {
        response =
            await ApiService().post(Urls.addUsers, data: payload, context);
      }
      if (!mounted) return;

      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          response.data['message'] ?? 'User added successfully!',
          duration: const Duration(seconds: 1),
        );
        Navigator.pop(context);
        widget.onClose();
        widget.sumbit!();
      }
    } catch (e) {
      if (mounted) {
        hideLoader(context);
        print("Error: $e");
      }
    }
  }

  @override
  void dispose() {
    fullName.dispose();
    emailController.dispose();
    mobileNum.dispose();
    super.dispose();
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
                      widget.userData != null
                          ? 'Edit User'
                          : Textstring().addUser,
                      style: Userstyles.addUserText,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: ColorPalatte.black,
                      ),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fullName,
                  style: Userstyles.fullnameLable,
                  decoration: InputDecoration(
                    labelText: Textstring().fullName,
                    labelStyle: Userstyles.fullnameLable,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                MobileInputWidget(
                  controller: mobileNum,
                  initialCountryCode: 'IN',
                  onCountryChanged: (phone) {
                    setState(() {
                      if (!mounted) return;
                      firstTwoDigits = phone;
                    });
                  },
                  label: Textstring().mobileNumber,
                  bottomBorderOnly: true,
                  color: ColorPalatte.black,
                ),
                const SizedBox(height: 10),
                TextField(
                  style: Userstyles.fullnameLable,
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: Textstring().emailAddressOptional,
                    labelStyle: Userstyles.fullnameLable,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedRole, // ✅ Set initial value
                  style: Userstyles.fullnameLable,
                  decoration: InputDecoration(
                    labelText: Textstring().selecRole,
                    labelStyle: Userstyles.fullnameLable,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  items: roles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role['roleId'], // ✅ Use roleId as value
                      child: Text(role['name']),
                    );
                  }).toList(),
                  onChanged: (String? selectedRoleId) {
                    setState(() {
                      _selectedRole = selectedRoleId;
                      print("Selected Role ID: $_selectedRole");
                    });
                  },
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: BuildPermission(selectedRole: _selectedRole),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        Textstring().viewPermissions,
                        style: Userstyles.viewPermission,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      handleSaveUser();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: ColorPalatte.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.userData != null
                            ? 'Update'
                            : Textstring().saveUser,
                        style: Userstyles.saveUserText,
                      ),
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
