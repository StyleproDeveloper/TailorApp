import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Core/Widgets/CustomTextInput.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/User/UserStyles.dart';

class Addbranchmodal extends StatefulWidget {
  const Addbranchmodal({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  _AddbranchmodalState createState() => _AddbranchmodalState();
}

class _AddbranchmodalState extends State<Addbranchmodal> {
  final TextEditingController mobileNum = TextEditingController();
  final TextEditingController countryCodeController =
      TextEditingController(text: '${' '}+91');
  final TextEditingController branchName = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController addressLine1 = TextEditingController();
  final TextEditingController searchStateController = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController postalCode = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController yourName = TextEditingController();

  String? selectedState;

  void handleSaveUser() async {
    if (mobileNum.text.isEmpty) {
      CustomSnackbar.showSnackbar(context, Textstring().mobileIsRequired,
          duration: const Duration(seconds: 1));
    }
    if (branchName.text.isEmpty) {
      CustomSnackbar.showSnackbar(context, Textstring().nameIsRequired,
          duration: const Duration(seconds: 1));
    }
    try {
      final Map<String, dynamic> payload = {
        'yourName': yourName.text.trim(),
        'shopName': branchName.text.trim(),
        'code': '',
        'branch_id': 0,
        'shopType': '1',
        'mobile': mobileNum.text.trim(),
        'secondaryMobile': '',
        'email': email.text.trim(),
        'website': '',
        'instagram_url': '',
        'facebook_url': '',
        'addressLine1': addressLine1.text.trim(),
        'street': '',
        'city': city.text.trim(),
        'state': selectedState,
        'postalCode': int.tryParse(postalCode.text.trim()) ?? 0,
        'subscriptionType': 1,
        'subscriptionEndDate': '2025-12-31',
      };

      print('object payload $payload');

      final response = await ApiService().post(
        Urls.shopName,
        data: payload,
        context
      );
      print('object response shop branch $response');
      if (response.data) {
        CustomSnackbar.showSnackbar(context, response.data['message'],
            duration: Duration(seconds: 1));
        widget.onClose();
      } else {
        CustomSnackbar.showSnackbar(context, response.data['message'],
            duration: Duration(seconds: 1));
      }
    } catch (e) {
      print('API Error: $e');
      CustomSnackbar.showSnackbar(context, 'Error: $e',
          duration: const Duration(seconds: 1));
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
            padding: const EdgeInsets.all(14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Textstring().addBranch,
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
                // -------- header -------
                CustomTextInput(
                    controller: yourName,
                    label: Textstring().name,
                    iconWidget: Icon(
                      Icons.person,
                      color: ColorPalatte.primary,
                    )),
                CustomTextInput(
                    controller: branchName,
                    label: Textstring().branchName,
                    iconWidget: Icon(
                      Icons.shop,
                      color: ColorPalatte.primary,
                    )),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextInput(
                        controller: countryCodeController,
                        label: '',
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      flex: 4,
                      child: CustomTextInput(
                        controller: mobileNum,
                        label: Textstring().mobileReq,
                        iconWidget: Icon(Icons.call_outlined,
                            color: ColorPalatte.primary),
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Mobile number is required';
                          } else if (value.length != 10) {
                            return 'Mobile number must be exactly 10 digits';
                          } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Only numeric values are allowed';
                          }
                          return null; // Validation passed
                        },
                      ),
                    ),
                  ],
                ),
                CustomTextInput(
                    controller: email,
                    label: Textstring().email,
                    iconWidget:
                        Icon(Icons.email_outlined, color: ColorPalatte.primary),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    }),
                CustomTextInput(
                  controller: addressLine1,
                  label: Textstring().addressLine1,
                  iconWidget:
                      Icon(Icons.location_on, color: ColorPalatte.primary),
                  isRequired: false,
                ),
                SizedBox(height: 5),
                CustomTextInput(
                    controller: city,
                    label: Textstring().city,
                    iconWidget:
                        Icon(Icons.location_city, color: ColorPalatte.primary),
                    isRequired: false),
                SizedBox(height: 5),
                CustomTextInput(
                  controller: searchStateController,
                  label: Textstring().state,
                  iconWidget:
                      Icon(Icons.location_on, color: ColorPalatte.primary),
                  keyboardType: TextInputType.text,
                  onChanged: (value) {
                    setState(() {
                      selectedState = value;
                    });
                  },
                ),
                SizedBox(height: 5),
                // CustomTextInput(
                //     controller: countryController,
                //     label: Textstring().country,
                //     iconWidget: Icon(Icons.flag, color: ColorPalatte.primary),
                //     keyboardType: TextInputType.number),
                // SizedBox(height: 5),

                CustomTextInput(
                    controller: postalCode,
                    label: Textstring().postalCode,
                    iconWidget:
                        Icon(Icons.tag_sharp, color: ColorPalatte.primary),
                    keyboardType: TextInputType.number),
                SizedBox(height: 5),
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
                        Textstring().saveBranch,
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
