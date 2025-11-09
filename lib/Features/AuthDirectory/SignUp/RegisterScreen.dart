import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Images.dart';
import 'package:tailorapp/Core/Constants/StaticValues.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CustomTextInput.dart';
import 'package:tailorapp/Core/Widgets/LoadingOverlay.dart';
import 'package:tailorapp/Core/Widgets/RequiredAlert.dart';
import '../../../Core/Services/Services.dart';
import '../../../Core/Services/Urls.dart';
import '../../../Core/Widgets/CustomSnakBar.dart';
import '../../../Routes/App_route.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final shopName = TextEditingController();
  final code = TextEditingController();
  final mobile = TextEditingController();
  final secondaryMobile = TextEditingController();
  final email = TextEditingController();
  final website = TextEditingController();
  final instagram = TextEditingController();
  final facebook = TextEditingController();
  final addressLine1 = TextEditingController();
  final street = TextEditingController();
  final city = TextEditingController();
  final postalCode = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController searchStateController = TextEditingController();

  final TextEditingController countryCodeController =
      TextEditingController(text: "+91");
  final TextEditingController mobileNumberController = TextEditingController();

  String? selectedShopType;
  String? selectedState;
  bool isLoading = false;
  String selectedCountryCode = "+91";

  Future<void> handleRegister(BuildContext context) async {
    if (name.text.trim().isEmpty || shopName.text.trim().isEmpty) {
      Requiredalert.showRequiredFieldsAlert(context);
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      final Map<String, dynamic> payload = {
        'branch_id': 0,
        'yourName': name.text.trim(),
        'shopName': shopName.text.trim(),
        'code': 'your_code_here',
        'shopType': selectedShopType,
        'mobile': mobileNumberController.text.trim(),
        'secondaryMobile': secondaryMobile.text.trim(),
        'email': email.text.trim(),
        'website': website.text.trim(),
        'instagram_url': instagram.text.trim(),
        'facebook_url': facebook.text.trim(),
        'addressLine1': addressLine1.text.trim(),
        'street': street.text.trim(),
        'city': city.text.trim(),
        'state': selectedState,
        'postalCode': postalCode.text.trim(),
        'subscriptionType': 1, //need to pass this 1 for now
        'subscriptionEndDate': '2025-12-31',
      };

      final response = await ApiService().post(
        Urls.shopName,
        data: payload,
        context
      );

      if (response.data) {
        // Set loading to false before navigation
        setState(() {
          isLoading = false;
        });
        
        // Navigate to success page instead of directly to login
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.registrationSuccess,
            (route) => false, // Remove all previous routes
          );
        }
      } else {
        CustomSnackbar.showSnackbar(context, response.data['message'],
            duration: Duration(seconds: 1));
      }
    } catch (e) {
      CustomSnackbar.showSnackbar(context, e.toString(),
          duration: Duration(seconds: 1));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedState = 'Select State';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mobileNumber =
          ModalRoute.of(context)?.settings.arguments as String? ?? '';
      print("Full Mobile Number: $mobileNumber");

      if (mobileNumber.isNotEmpty && mobileNumber.startsWith('+')) {
        final match = RegExp(r'^(\+\d{1,2})(\d+)$').firstMatch(mobileNumber);
        if (match != null) {
          String countryCode = match.group(1)!;
          String number = match.group(2)!;

          setState(() {
            countryCodeController.text = countryCode;
            mobileNumberController.text = number;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    name.dispose();
    shopName.dispose();
    code.dispose();
    mobile.dispose();
    secondaryMobile.dispose();
    email.dispose();
    website.dispose();
    instagram.dispose();
    facebook.dispose();
    addressLine1.dispose();
    street.dispose();
    city.dispose();
    postalCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
        isLoading: isLoading,
        child: Scaffold(
          backgroundColor: ColorPalatte.white,
          appBar: Commonheader(title: Textstring().shopReg),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomTextInput(
                    controller: name,
                    label: Textstring().name,
                    iconWidget: Icon(Icons.person, color: ColorPalatte.primary),
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return Textstring().nameIsRequired;
                      } else if (value.length < 3) {
                        return Textstring().nameMustBeAtLeast3Characters;
                      }
                      return null;
                    }),
                SizedBox(height: 5),
                CustomTextInput(
                    controller: shopName,
                    label: Textstring().shopName,
                    iconWidget: Icon(Icons.store, color: ColorPalatte.primary),
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return Textstring().shopNameIsRequired;
                      } else if (value.length < 3) {
                        return Textstring().shopNameMustBeAtLeast3Characters;
                      }
                      return null;
                    }),
                SizedBox(height: 5),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextInput(
                        controller: countryCodeController,
                        label: '',
                        iconWidget: Icon(Icons.emoji_flags_outlined,
                            color: ColorPalatte.primary),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      flex: 4,
                      child: CustomTextInput(
                        controller: mobileNumberController,
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
                SizedBox(height: 5),
                // MobileInputWidget(
                //   controller: secondaryMobile,
                //   isRequired: false,
                //   color: ColorPalatte.black,
                //   label: Textstring().secondaryMobile,
                //   initialCountryCode: 'IN',
                //   onCountryChanged: (code) {
                //     setState(() {
                //       selectedCountryCode = code;
                //     });
                //   },
                // ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextInput(
                        controller: countryCodeController,
                        label: '',
                        iconWidget: Icon(Icons.emoji_flags_outlined,
                            color: ColorPalatte.primary),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      flex: 4,
                      child: CustomTextInput(
                        controller: secondaryMobile,
                        label: Textstring().secondaryMobile,
                        iconWidget: Icon(Icons.call_outlined,
                            color: ColorPalatte.primary),
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        validator: (value) {
                          if (value?.length != 10 && value!.isNotEmpty) {
                            return 'Mobile number must be exactly 10 digits';
                          } else if ((!RegExp(r'^[0-9]+$').hasMatch(value!)) &&
                              value.isNotEmpty) {
                            return 'Only numeric values are allowed';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
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
                SizedBox(height: 5),
                CustomTextInput(
                  controller: website,
                  label: Textstring().website,
                  iconWidget: Icon(Icons.public, color: ColorPalatte.primary),
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !RegExp(r'^(http|https):\/\/([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,})(\/.*)?$')
                            .hasMatch(value)) {
                      return 'Enter a valid website URL';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 5),
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
                // InputDecorator(
                //   decoration: InputDecoration(
                //     border: OutlineInputBorder(),
                //     contentPadding: EdgeInsets.symmetric(horizontal: 12),
                //   ),
                //   child: DropdownButtonHideUnderline(
                //     child: DropdownButton2<String>(
                //       isExpanded: true,
                //       value: Staticvalues.states.contains(selectedState)
                //           ? selectedState
                //           : null,
                //       items: Staticvalues.states.map((String item) {
                //         return DropdownMenuItem<String>(
                //           value: item,
                //           child: Text(item),
                //         );
                //       }).toList(),
                //       onChanged: (value) {
                //         setState(() {
                //           selectedState = value;
                //         });
                //       },
                //       dropdownSearchData: DropdownSearchData(
                //         searchController: searchStateController,
                //         searchInnerWidgetHeight: 50.0,
                //         searchInnerWidget: Padding(
                //           padding: const EdgeInsets.all(8),
                //           child: TextField(
                //             controller: searchStateController,
                //             decoration: InputDecoration(
                //               hintText: "Search...",
                //               border: OutlineInputBorder(),
                //             ),
                //           ),
                //         ),
                //         searchMatchFn: (item, searchValue) {
                //           return item.value!
                //               .toLowerCase()
                //               .contains(searchValue.toLowerCase());
                //         },
                //       ),
                //       buttonStyleData: const ButtonStyleData(
                //           height: 50,
                //           padding: EdgeInsets.symmetric(horizontal: 16)),
                //       menuItemStyleData: const MenuItemStyleData(height: 40),
                //     ),
                //   ),
                // ),
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

                CustomTextInput(
                    controller: postalCode,
                    label: Textstring().postalCode,
                    maxLength: 6,
                    iconWidget:
                        Icon(Icons.tag_sharp, color: ColorPalatte.primary),
                    keyboardType: TextInputType.number),
                SizedBox(height: 5),
                CustomTextInput(
                  controller: instagram,
                  label: Textstring().instagram_url,
                  iconWidget: FittedBox(
                    fit: BoxFit.scaleDown, // Shrinks without extra space
                    child: Image.asset(
                      Images.instagramIcon,
                      width: 22, // Adjust width
                      height: 22, // Adjust height
                    ),
                  ),
                  isRequired: false,
                ),

                SizedBox(height: 5),
                CustomTextInput(
                    controller: facebook,
                    label: Textstring().facebook_url,
                    iconWidget:
                        Icon(Icons.facebook, color: ColorPalatte.primary),
                    isRequired: false),
                SizedBox(height: 5),
                // Shop Type Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                      labelText: "Select Shop Type",
                      labelStyle: TextStyle(color: ColorPalatte.gray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: ColorPalatte.borderGray)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: ColorPalatte.borderGray))),
                  value: selectedShopType,
                  items: Staticvalues.shopTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedShopType = value;
                    });
                  },
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => handleRegister(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: ColorPalatte.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: ColorPalatte.white),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
