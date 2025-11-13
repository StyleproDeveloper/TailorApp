import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Core/Widgets/CustomTextInput.dart';
import 'package:tailorapp/GlobalVariables.dart';

class ShopDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? shopData;
  
  const ShopDetailsScreen({super.key, this.shopData});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController secondaryMobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressLine1Controller = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController(text: '+91');
  final TextEditingController countryCodeSecondaryController = TextEditingController(text: '+91');

  String selectedShopType = 'Store';
  bool isLoading = false;
  bool isEditing = false;
  Map<String, dynamic>? shopData;

  final List<String> shopTypes = ['Store', 'Workshop'];

  @override
  void initState() {
    super.initState();
    // Always fetch fresh data from API to ensure all fields are loaded
    // Even if shopData is passed, it might be incomplete (e.g., from BranchesScreen)
    _fetchShopData();
  }

  Future<void> _fetchShopData() async {
    setState(() => isLoading = true);
    
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      CustomSnackbar.showSnackbar(context, "Shop ID is missing", duration: Duration(seconds: 2));
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await ApiService().get('${Urls.shopName}/$shopId', context);
      
      if (response.data != null) {
        // Handle nested response structure: { success: true, data: {...} }
        final responseData = response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
        final shopDataFromResponse = responseData['data'] ?? responseData;
        
        setState(() {
          shopData = shopDataFromResponse is Map ? shopDataFromResponse as Map<String, dynamic> : null;
          _loadShopData();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch shop data");
      }
    } catch (e) {
      setState(() => isLoading = false);
      CustomSnackbar.showSnackbar(context, "Error fetching shop data: $e", duration: Duration(seconds: 2));
    }
  }

  void _loadShopData() {
    if (shopData != null) {
      shopNameController.text = shopData!['shopName']?.toString() ?? '';
      mobileController.text = shopData!['mobile']?.toString() ?? '';
      secondaryMobileController.text = shopData!['secondaryMobile']?.toString() ?? '';
      emailController.text = shopData!['email']?.toString() ?? '';
      addressLine1Controller.text = shopData!['addressLine1']?.toString() ?? '';
      streetController.text = shopData!['street']?.toString() ?? '';
      cityController.text = shopData!['city']?.toString() ?? '';
      stateController.text = shopData!['state']?.toString() ?? '';
      postalCodeController.text = shopData!['postalCode']?.toString() ?? '';
      selectedShopType = shopData!['shopType']?.toString() ?? 'Store';
      
      // Set country codes if available, otherwise keep default +91
      if (shopData!['countryCode'] != null && shopData!['countryCode'].toString().isNotEmpty) {
        countryCodeController.text = shopData!['countryCode'];
      }
      if (shopData!['secondaryCountryCode'] != null && shopData!['secondaryCountryCode'].toString().isNotEmpty) {
        countryCodeSecondaryController.text = shopData!['secondaryCountryCode'];
      }
    }
  }

  Future<void> _updateShop() async {
    if (shopNameController.text.trim().isEmpty) {
      CustomSnackbar.showSnackbar(context, "Shop name is required", duration: Duration(seconds: 2));
      return;
    }

    setState(() => isLoading = true);

    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      CustomSnackbar.showSnackbar(context, "Shop ID is missing", duration: Duration(seconds: 2));
      setState(() => isLoading = false);
      return;
    }

    try {
      final payload = {
        'shopName': shopNameController.text.trim(),
        'shopType': selectedShopType,
        'mobile': mobileController.text.trim(),
        'secondaryMobile': secondaryMobileController.text.trim().isNotEmpty 
            ? secondaryMobileController.text.trim() 
            : '',
        'email': emailController.text.trim().isNotEmpty 
            ? emailController.text.trim() 
            : '',
        'addressLine1': addressLine1Controller.text.trim().isNotEmpty 
            ? addressLine1Controller.text.trim() 
            : '',
        'street': streetController.text.trim().isNotEmpty 
            ? streetController.text.trim() 
            : '',
        'city': cityController.text.trim().isNotEmpty 
            ? cityController.text.trim() 
            : '',
        'state': stateController.text.trim().isNotEmpty 
            ? stateController.text.trim() 
            : '',
        'postalCode': postalCodeController.text.trim().isNotEmpty 
            ? postalCodeController.text.trim() 
            : '',
      };

      final response = await ApiService().put('${Urls.shopName}/$shopId', context, data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomSnackbar.showSnackbar(
          context, 
          "Shop details updated successfully", 
          duration: Duration(seconds: 2)
        );
        setState(() => isEditing = false);
        _fetchShopData(); // Refresh data
      } else {
        throw Exception("Failed to update shop details");
      }
    } catch (e) {
      CustomSnackbar.showSnackbar(
        context, 
        "Error updating shop details: $e", 
        duration: Duration(seconds: 2)
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: Commonheader(title: 'Shop Details'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: Commonheader(
        title: 'Shop Details',
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: ColorPalatte.primary),
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      backgroundColor: ColorPalatte.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Name
            CustomTextInput(
              controller: shopNameController,
              label: 'Shop Name',
              iconWidget: Icon(Icons.store, color: ColorPalatte.primary),
              isRequired: true,
              isEnabled: isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Shop name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Shop Type
            Text(
              'Shop Type',
              style: TextStyle(
                fontSize: 16,
                fontFamily: Fonts.Medium,
                color: ColorPalatte.black,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: ColorPalatte.borderGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedShopType,
                  isExpanded: true,
                  items: shopTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: isEditing ? (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedShopType = newValue);
                    }
                  } : null,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Primary Mobile
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextInput(
                    controller: countryCodeController,
                    label: '',
                    iconWidget: Icon(Icons.emoji_flags_outlined, color: ColorPalatte.primary),
                    isEnabled: false, // Always disabled since not sent to backend
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  flex: 4,
                  child: CustomTextInput(
                    controller: mobileController,
                    label: 'Primary Mobile',
                    iconWidget: Icon(Icons.call_outlined, color: ColorPalatte.primary),
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    isRequired: true,
                    isEnabled: isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number is required';
                      } else if (value.length != 10) {
                        return 'Mobile number must be exactly 10 digits';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Secondary Mobile
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextInput(
                    controller: countryCodeSecondaryController,
                    label: '',
                    iconWidget: Icon(Icons.emoji_flags_outlined, color: ColorPalatte.primary),
                    isEnabled: false, // Always disabled since not sent to backend
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  flex: 4,
                  child: CustomTextInput(
                    controller: secondaryMobileController,
                    label: 'Secondary Mobile (Optional)',
                    iconWidget: Icon(Icons.call_outlined, color: ColorPalatte.primary),
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    isEnabled: isEditing,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Email
            CustomTextInput(
              controller: emailController,
              label: 'Email (Optional)',
              iconWidget: Icon(Icons.email, color: ColorPalatte.primary),
              keyboardType: TextInputType.emailAddress,
              isEnabled: isEditing,
            ),
            SizedBox(height: 16),

            // Address Line 1
            CustomTextInput(
              controller: addressLine1Controller,
              label: 'Address Line 1 (Optional)',
              iconWidget: Icon(Icons.location_on, color: ColorPalatte.primary),
              maxLines: 3,
              isEnabled: isEditing,
            ),
            SizedBox(height: 16),

            // Street
            CustomTextInput(
              controller: streetController,
              label: 'Street (Optional)',
              iconWidget: Icon(Icons.streetview, color: ColorPalatte.primary),
              isEnabled: isEditing,
            ),
            SizedBox(height: 16),

            // City
            CustomTextInput(
              controller: cityController,
              label: 'City (Optional)',
              iconWidget: Icon(Icons.location_city, color: ColorPalatte.primary),
              isEnabled: isEditing,
            ),
            SizedBox(height: 16),

            // State
            CustomTextInput(
              controller: stateController,
              label: 'State (Optional)',
              iconWidget: Icon(Icons.map, color: ColorPalatte.primary),
              isEnabled: isEditing,
            ),
            SizedBox(height: 16),

            // Postal Code
            CustomTextInput(
              controller: postalCodeController,
              label: 'Postal Code (Optional)',
              iconWidget: Icon(Icons.pin_drop, color: ColorPalatte.primary),
              keyboardType: TextInputType.number,
              maxLength: 6,
              isEnabled: isEditing,
            ),
            SizedBox(height: 32),

            // Action Buttons
            if (isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => isEditing = false);
                        _loadShopData(); // Reset to original data
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: Fonts.Bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalatte.primary,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Update',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: Fonts.Bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    shopNameController.dispose();
    mobileController.dispose();
    secondaryMobileController.dispose();
    emailController.dispose();
    addressLine1Controller.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryCodeController.dispose();
    countryCodeSecondaryController.dispose();
    super.dispose();
  }
}
