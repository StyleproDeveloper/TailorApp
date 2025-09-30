import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CustomDatePicker.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Core/Widgets/CustomTextInput.dart';
import 'package:tailorapp/Core/Widgets/RequiredAlert.dart';
import 'package:tailorapp/Features/RootDirectory/customer/CustomerStyle.dart';
import 'package:tailorapp/Features/RootDirectory/customer/ToggleNotification.dart';
import '../../../Core/Tools/Helper.dart';
import '../../../GlobalVariables.dart';
import 'Widgets/GenderSelection.dart';

class Customerinfo extends StatefulWidget {
  const Customerinfo({super.key, this.customerId, this.shouldNavigateBack = false});

  final int? customerId;
  final bool shouldNavigateBack; // New parameter to control navigation

  @override
  State<Customerinfo> createState() => _CustomerinfoState();
}

class _CustomerinfoState extends State<Customerinfo> {
  final TextEditingController name = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController secondaryMobile = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController dob = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController remark = TextEditingController();
  final TextEditingController countryCodeController =
      TextEditingController(text: '+91');
  final TextEditingController countryCodeSecondaryController =
      TextEditingController(text: '+91');

  String selectedGender = 'male';
  String selectedCountryCodeMobile = '+91';
  String selectedCountryCodeSecondMobile = '+91';
  bool _notificationOption = false;
  bool _addressOption = false;
  bool _addressManuallyOpened = false;
  int? customerId;

  final List<String> genderList = ["Male", "Female", "Other"];

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final customerData = widget.customerId ?? ModalRoute.of(context)?.settings.arguments as int?;
    if (customerData != null) {
      customerId = customerData;
      _clearForm(); // Clear form before loading fresh data
      _fetchCustomerDetails();
    }
  });
}

  void _clearForm() {
    name.clear();
    mobile.clear();
    secondaryMobile.clear();
    email.clear();
    dob.clear();
    address.clear();
    remark.clear();
    
    selectedGender = 'male';
    _notificationOption = false;
    _addressOption = false;
    _addressManuallyOpened = false;
  }

  void _fetchCustomerDetails() async {
    int? shopId = GlobalVariables.shopIdGet;
    showLoader(context);

    if (shopId == null) {
      print("Shop ID is missing");
      return;
    }

    final requestUrl = "${Urls.customer}/$shopId/$customerId";

    try {
      final response = await ApiService().get(requestUrl, context);
      hideLoader(context);
      if (response.data != null) {
        final customerData = response.data;
        print('Debug: customer data:: $customerData');

        setState(() {
          // Always update fields with fresh data from API
          name.text = customerData['name'] ?? '';
          mobile.text = customerData['mobile'] ?? '';
          secondaryMobile.text = customerData['secondaryMobile'] ?? '';
          email.text = customerData['email'] ?? '';
          dob.text = formatDate(customerData['dateOfBirth']);
          address.text = customerData['addressLine1'] ?? '';
          remark.text = customerData['remark'] ?? '';

          selectedGender = customerData['gender'] ?? 'male';
          _notificationOption = customerData['notificationOptIn'] ?? false;
          _addressOption = address.text.isNotEmpty;
          
          print('🔄 Form populated - Gender: ${customerData['gender']} -> $selectedGender');
        });
      }
    } catch (e) {
      hideLoader(context);
      print('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    void handleNewCustomer() async {
      print('🔄 Update button clicked - Customer ID: $customerId');
      int? id = GlobalVariables.shopIdGet;
      int? branchId = GlobalVariables.branchId;
      
      if (id == null) {
        CustomSnackbar.showSnackbar(
          context,
          "Shop ID is missing",
          duration: Duration(seconds: 2),
        );
        return;
      }
      
      if (branchId == null) {
        CustomSnackbar.showSnackbar(
          context,
          "Branch ID is missing",
          duration: Duration(seconds: 2),
        );
        return;
      }
      
      if (name.text.trim().isEmpty || mobile.text.trim().isEmpty) {
        Requiredalert.showRequiredFieldsAlert(context);
        return;
      }

      // Show loading indicator
      showLoader(context);

      String formattedDob = '';
      if (dob.text.trim().isNotEmpty) {
        // Check if date is in the future
        try {
          final List<String> dateParts = dob.text.trim().split('/');
          if (dateParts.length == 3) {
            final int day = int.parse(dateParts[0]);
            final int month = int.parse(dateParts[1]);
            final int year = int.parse(dateParts[2]);
            final DateTime selectedDate = DateTime(year, month, day);
            final DateTime now = DateTime.now();
            final DateTime today = DateTime(now.year, now.month, now.day);
            
            if (selectedDate.isAfter(today)) {
              hideLoader(context);
              CustomSnackbar.showSnackbar(
                context,
                "Date of birth cannot be in the future",
                duration: Duration(seconds: 2),
              );
              return;
            }
          }
        } catch (e) {
          // If date parsing fails, continue with format validation
        }
        
        formattedDob = formatDateForApi(dob.text.trim());
        if (formattedDob.isEmpty && dob.text.trim().isNotEmpty) {
          hideLoader(context);
          CustomSnackbar.showSnackbar(
            context,
            "Invalid date format. Please use DD/MM/YYYY",
            duration: Duration(seconds: 2),
          );
          return;
        }
      }

      try {
        final Map<String, dynamic> payload = {
          'shop_id': id,
          'name': name.text.trim(),
          'gender': selectedGender.toLowerCase(),
          'remark': remark.text.trim().isNotEmpty ? remark.text.trim() : '',
          'mobile': mobile.text.trim(),
          'secondaryMobile': secondaryMobile.text.trim().isNotEmpty
              ? secondaryMobile.text.trim()
              : '',
          'email': email.text.trim().isNotEmpty ? email.text.trim() : '',
          'dateOfBirth': formattedDob.isNotEmpty ? formattedDob : '',
          'addressLine1':
              address.text.trim().isNotEmpty ? address.text.trim() : '',
          'notificationOptIn': _notificationOption,
          'branch_id': branchId.toString(),
        };

        print('Payload: $payload | Customer ID: $customerId');
        
        Response response;
        if (customerId != null) {
          // Update existing customer
          response = await ApiService()
              .put('${Urls.customer}/$id/$customerId', data: payload, context);
        } else {
          // Create new customer
          response =
              await ApiService().post(Urls.customer, data: payload, context);
        }

        hideLoader(context);

        if (response.data != null && response.statusCode == 200) {
          String message = customerId != null 
              ? 'Customer updated successfully'
              : 'Customer created successfully';
          
          if (response.data['message'] != null) {
            message = response.data['message'];
          }

          print('✅ Customer operation successful - Customer ID: $customerId');
          print('✅ Message: $message');
          
          CustomSnackbar.showSnackbar(
            context, 
            message,
            duration: Duration(seconds: 2)
          );
          
          // Navigate back for new customer creation when called from create order page
          if (customerId == null && widget.shouldNavigateBack) {
            print('🔄 Navigating back for new customer creation from create order page');
            print('📊 Full API Response: ${response.data}');
            
            // Try different possible response structures
            int? returnedCustomerId;
            if (response.data['customerId'] != null) {
              returnedCustomerId = response.data['customerId'];
            } else if (response.data['id'] != null) {
              returnedCustomerId = response.data['id'];
            } else if (response.data['customer'] != null && response.data['customer']['id'] != null) {
              returnedCustomerId = response.data['customer']['id'];
            } else {
              print('⚠️ Could not find customer ID in response');
              returnedCustomerId = 0; // Fallback
            }
            
            // Return the created customer data
            final customerData = {
              'customerId': returnedCustomerId,
              'name': name.text.trim(),
              'mobile': mobile.text.trim(),
              'email': email.text.trim(),
              'address': address.text.trim(),
              'dateOfBirth': dob.text.trim(),
              'gender': selectedGender,
              'secondaryMobile': secondaryMobile.text.trim(),
              'addressLine1': address.text.trim(),
              'remark': remark.text.trim(),
            };
            print('📤 Returning customer data: $customerData');
            Navigator.pop(context, customerData);
          } else if (customerId == null) {
            print('✅ Customer created successfully, staying on page');
            // For direct customer creation (not from create order), stay on page
          } else {
            print('✅ Staying on page for customer update');
          }
        } else {
          CustomSnackbar.showSnackbar(
            context, 
            response.statusMessage ?? 'Operation failed',
            duration: Duration(seconds: 2)
          );
        }
      } catch (e) {
        hideLoader(context);
        print('Error in handleNewCustomer: ${e.toString()}');
        
        CustomSnackbar.showSnackbar(
          context,
          customerId != null 
              ? 'Failed to update customer. Please try again.'
              : 'Failed to create customer. Please try again.',
          duration: Duration(seconds: 2),
        );
      }
    }

    String? validateName(String? value) {
      if (value == null || value.isEmpty) {
        return "Name is required";
      } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
        return "Only alphabets and spaces are allowed";
      }
      return null;
    }

    return Scaffold(
      appBar: Commonheader(
          title: customerId != null
              ? Textstring().updateCustomer
              : Textstring().addNewCustomer),
      backgroundColor: ColorPalatte.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              child: Column(
                children: [
                  SizedBox(height: 15),
                  CustomTextInput(
                    controller: name,
                    label: Textstring().name,
                    iconWidget: Icon(Icons.person, color: ColorPalatte.primary),
                    isRequired: true,
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[a-zA-Z\s]+$')),
                    ],
                    validator: validateName,
                  ),
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
                          controller: mobile,
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
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Column(
                    children: [
                      GenderSelection(
                        key: ValueKey('gender_$selectedGender'),
                        initialGender: selectedGender,
                        onGenderSelected: (gender) {
                          setState(() {
                            selectedGender = gender;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  CustomToggleSwitch(
                      label: Textstring().notificationNeed,
                      value: _notificationOption,
                      onChanged: (value) {
                        setState(() {
                          _notificationOption = value;
                        });
                      }),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextInput(
                          controller: countryCodeSecondaryController,
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
                  CustomTextInput(
                    controller: email,
                    label: Textstring().email,
                    iconWidget: Icon(Icons.email, color: ColorPalatte.primary),
                  ),
                  CustomDatePicker(
                      label: Textstring().dateofbirth, controller: dob),
                  Row(
                    children: [
                      Checkbox(
                          value: _addressOption,
                          checkColor: ColorPalatte.white,
                          activeColor: ColorPalatte.primary,
                          onChanged: (bool? value) {
                            setState(() {
                              _addressOption = value!;
                              _addressManuallyOpened = true;
                            });
                          }),
                      Text(
                        Textstring().showAddress,
                        style: Customerstyle.addressShown,
                      ),
                    ],
                  ),
                  if (_addressOption)
                    CustomTextInput(
                      controller: address,
                      label: Textstring().addressLine1,
                      iconWidget: Icon(Icons.location_city,
                          color: ColorPalatte.primary),
                      maxLines: 6,
                      minLines: 5,
                    ),
                  SizedBox(height: 10),
                  CustomTextInput(
                    controller: remark,
                    label: Textstring().remark,
                    iconWidget: Icon(Icons.note, color: ColorPalatte.primary),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      handleNewCustomer();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: ColorPalatte.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      customerId != null
                          ? Textstring().update
                          : Textstring().submit,
                      style: TextStyle(
                          color: ColorPalatte.white,
                          fontFamily: Fonts.Bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
