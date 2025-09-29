import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/CreateOrder/CreateOrderStyle.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/CreateOrder/PatternSelectionModal.dart';
import 'package:tailorapp/Routes/App_route.dart';
import '../../../../Core/Services/Services.dart';
import '../../../../Core/Services/Urls.dart';
import '../../../../Core/Widgets/CustomDatePicker.dart';
import '../../../../Core/Widgets/CustomLoader.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';
import '../../../../GlobalVariables.dart';
import '../../customer/CustomerInfo.dart';

class CreateOrderScreen extends StatefulWidget {
  CreateOrderScreen({super.key, this.orderId});
  dynamic orderId;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String selectedOrderType = "Stitching";
  List<Map<String, dynamic>> customers = [];
  Map<String, dynamic>? selectedCustomer;
  TextEditingController dropdownCustomerController = TextEditingController();
  TextEditingController dropdownDressController = TextEditingController();
  int? selectedCustomerId;
  List<Map<String, dynamic>> dressTypes = [];
  bool isUrgent = false;
  List<OrderItem> orderItems = [OrderItem()];
  List<Map<String, TextEditingController>> additionalCostControllers = [];
  bool isCourierChecked = false;
  bool isGstChecked = false;
  final TextEditingController courierController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  TextEditingController advanceAmountController = TextEditingController();
  TextEditingController totalCostController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  int? orderItemMeasurementId;
  int? orderItemPatternId;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  final ScrollController _scrollController = ScrollController();
  int pageNumber = 1;
  final int pageSize = 10;
  bool hasMoreData = true;
  Timer? _debounce;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Initialize additional cost controllers
    additionalCostControllers.add({
      'description': TextEditingController(),
      'amount': TextEditingController(),
    });

    // Fetch data and handle orderId
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First, fetch only initial customers (10) and dress types for faster loading
      await Future.wait([
        _fetchInitialCustomers(),
        fetchDressTypeData(
          pageNumber: 1,
          pageSize: 20,
          existingDressTypes: [],
          initialFetch: true,
        ),
      ]);

      // Then, fetch product details if orderId exists
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        setState(() {
          widget.orderId = args;
        });
        await fetchProductDetail();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (var item in orderItems) {
      for (var measurement in item.measurements) {
        (measurement['value'] as TextEditingController).dispose();
      }
      item.specialInstructions?.dispose();
      item.deliveryDate?.dispose();
      item.originalCost?.dispose();
    }
    for (var cost in additionalCostControllers) {
      cost['description']?.dispose();
      cost['amount']?.dispose();
    }
    courierController.dispose();
    gstController.dispose();
    discountController.dispose();
    advanceAmountController.dispose();
    totalCostController.dispose();
    dropdownCustomerController.dispose();
    dropdownDressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialCustomers() async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    // Fetch only first 10 customers for fast initial load
    try {
      final String requestUrl = "${Urls.customer}/$id?pageNumber=1&pageSize=10";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data is Map<String, dynamic>) {
        List<dynamic> customerData = response.data['data'];
        setState(() {
          customers = customerData.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          customers = [];
        });
      }
    } catch (e) {
      setState(() {
        customers = [];
      });
    }
  }

  Future<void> fetchCustomerData() async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    // Fetch all customers with pagination (for refresh scenarios)
    await _fetchAllCustomers(id);
  }

  Future<void> _fetchAllCustomers(int shopId, {int pageNumber = 1, int pageSize = 50}) async {
    try {
      final String requestUrl = "${Urls.customer}/$shopId?pageNumber=$pageNumber&pageSize=$pageSize";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data is Map<String, dynamic>) {
        List<dynamic> customerData = response.data['data'];
        List<Map<String, dynamic>> newCustomers = customerData.cast<Map<String, dynamic>>();
        
        setState(() {
          if (pageNumber == 1) {
            customers = newCustomers;
          } else {
            customers.addAll(newCustomers);
          }
        });

        // If we got a full page, there might be more customers
        if (newCustomers.length == pageSize) {
          await _fetchAllCustomers(shopId, pageNumber: pageNumber + 1, pageSize: pageSize);
        }
      } else {
        Future.microtask(() => CustomSnackbar.showSnackbar(
              context,
              'Customer not found',
              duration: const Duration(seconds: 1),
            ));
        setState(() {
          customers = [];
        });
      }
    } catch (e) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            'Failed to load customers',
            duration: Duration(seconds: 2),
          ));
    }
  }

  Future<List<Map<String, dynamic>>> fetchDressTypeData({
    required int pageNumber,
    required int pageSize,
    bool loadMore = false,
    required List<Map<String, dynamic>> existingDressTypes,
    bool initialFetch = false,
  }) async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return existingDressTypes;
    }

    final String requestUrl =
        "${Urls.addDress}/$id?pageNumber=$pageNumber&pageSize=$pageSize";
    try {
      final response = await ApiService().get(requestUrl, context);
      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedData = response.data['data'];
        List<Map<String, dynamic>> newDressTypes = fetchedData.map((dress) {
          return {
            "id": dress['dressTypeId'],
            "name": dress['name'],
          };
        }).toList();

        if (initialFetch) {
          setState(() {
            dressTypes = newDressTypes;
          });
        }

        List<Map<String, dynamic>> allDressTypes = [
          ...existingDressTypes,
          ...newDressTypes
        ];
        if (newDressTypes.length == pageSize) {
          return await fetchDressTypeData(
            pageNumber: pageNumber + 1,
            pageSize: pageSize,
            loadMore: true,
            existingDressTypes: allDressTypes,
          );
        }
        return allDressTypes;
      } else {
        Future.microtask(() => CustomSnackbar.showSnackbar(
              context,
              'No dress types found',
              duration: Duration(seconds: 2),
            ));
        return [];
      }
    } catch (e) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            'Failed to load dress types',
            duration: Duration(seconds: 2),
          ));
      return existingDressTypes;
    }
  }

  Future<void> fetchMeasurements(int? dressTypeId, OrderItem orderItem) async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null || dressTypeId == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID or Dress Type ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    final String requestUrl = "${Urls.orderDressTypeMea}/$id/$dressTypeId";
    print("Request URL for Measurements: $requestUrl");

    try {
      final response = await ApiService().get(requestUrl, context);
      print('Debug: Measurement Data: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedMeasurements =
            response.data["DressTypeMeasurement"] ?? [];

        // Create a map of existing measurements for quick lookup
        final existingMeasurements = {
          for (var m in orderItem.measurements)
            m['name'].toString().toLowerCase().replaceAll(' ', '_'):
                m['value'] as TextEditingController,
        };

        if (!mounted) return; // Check if the widget is still mounted
        setState(() {
          orderItem.measurements =
              fetchedMeasurements.map<Map<String, dynamic>>((measurement) {
            final name = measurement['name'].toString();
            final key = name.toLowerCase().replaceAll(' ', '_');
            final controller =
                existingMeasurements[key] ?? TextEditingController(text: '0');
            print(
                'Measurement: $name, controller.text=${controller.text}, hashCode=${controller.hashCode}');
            return {
              'name': name,
              'dressTypeMeasurementId':
                  measurement['dressTypeMeasurementId'] ?? 0,
              'value': controller,
            };
          }).toList();

          orderItem.measurements.addAll(orderItem.measurements.where((m) {
            final key = m['name'].toString().toLowerCase().replaceAll(' ', '_');
            return !fetchedMeasurements.any((fm) =>
                fm['name'].toString().toLowerCase().replaceAll(' ', '_') ==
                key);
          }));
          print(
              "Updated Measurements for OrderItem: ${orderItem.measurements}");
        });
      } else {
        if (!mounted) return; // Check if the widget is still mounted
        setState(() {
          orderItem.measurements = [];
        });
      }
    } catch (e) {
      print("Failed to load measurements: $e");
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Failed to load measurements: $e",
            duration: Duration(seconds: 2),
          ));
      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        orderItem.measurements =
            orderItem.measurements; // Preserve existing data on error
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchPatterns(int? dressTypeId) async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null || dressTypeId == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID or Dress Type ID is missing",
            duration: Duration(seconds: 2),
          ));
      return [];
    }

    final String requestUrl = "${Urls.orderDressTypeMea}/$id/$dressTypeId";
    print("Request URL for Patterns: $requestUrl");

    try {
      final response = await ApiService().get(requestUrl, context);
      print('Raw pattern response: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedPatterns =
            response.data["DressTypeDressPattern"] ?? [];
        final patterns = fetchedPatterns
            .map<Map<String, dynamic>>((pattern) {
              final details = pattern['PatternDetails'] ?? {};
              final id = pattern['_id']?.toString();
              if (id == null) {
                print('Warning: Missing _id for pattern: $pattern');
                return {};
              }
              return {
                '_id': id,
                'category': details['category']?.toString() ?? 'Unknown',
                'name': details['name'] is List
                    ? (details['name'] as List).cast<String>()
                    : [details['name']?.toString() ?? ''],
                'selection': details['selection']?.toString() ?? 'multiple',
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();
        print('Processed patterns: $patterns');
        return patterns;
      }
      return [];
    } catch (e) {
      print("Failed to load patterns: $e");
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Failed to load patterns: $e",
            duration: Duration(seconds: 2),
          ));
      return [];
    }
  }

 Future<void> fetchProductDetail() async {
  showLoader(context);
  int? shopId = GlobalVariables.shopIdGet;
  int? orderId = widget.orderId;
  if (orderId == null || shopId == null) {
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    hideLoader(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shop ID or Order ID is missing')),
    );
    return;
  }

  try {
    String url =
        "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=10&orderId=$orderId";
    final response = await ApiService().get(url, context);
    hideLoader(context);

    if (response.data != null && response.data is Map<String, dynamic>) {
      final data = response.data['data'];
      if (data != null && data is List && data.isNotEmpty) {
        final order = data[0];

        if (!mounted) return;
        setState(() {
          selectedOrderType = _mapOrderType(order['stitchingType']);
          selectedCustomerId = order['customerId'];
          selectedCustomer = customers.firstWhere(
            (customer) => customer['customerId'] == selectedCustomerId,
            orElse: () => {},
          );
          if (selectedCustomer != null && selectedCustomer!.isNotEmpty) {
            dropdownCustomerController.text = selectedCustomer!['name'];
          } else {
            selectedCustomerId = null;
            dropdownCustomerController.text = '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Customer ID $selectedCustomerId not found')),
            );
          }

          isUrgent = order['urgent'] ?? false;

          if (order['courierCharge'] != null) {
            courierController.text = order['courierCharge']?.toString() ?? '';
            isCourierChecked = true;
          }
          if (order['gst'] == true) {
            gstController.text = order['gstNumber']?.toString() ?? '';
            isGstChecked = true;
          }
          discountController.text = order['discount']?.toString() ?? '0';

          final double estimationCost =
              double.tryParse(order['estimationCost']?.toString() ?? '0') ??
                  0.0;
          totalCostController.text = estimationCost.toStringAsFixed(2);

          advanceAmountController.text =
              order['advancereceived']?.toString() ?? '';

          orderItems = (order['items'] as List<dynamic>).map((item) {
            print("Selected Dress Type::::: ${item['dressTypeId']}");
            final dressType = dressTypes.firstWhere(
              (dress) => dress['id'] == item['dressTypeId'],
              orElse: () => {},
            );

            if (dressType.isEmpty) {
              print(
                  "Warning: No dress type found for dressTypeId: ${item['dressTypeId']}");
              fetchDressTypeData(
                pageNumber: 1,
                pageSize: 20,
                existingDressTypes: dressTypes,
              ).then((newDressTypes) {
                setState(() {
                  dressTypes = newDressTypes;
                  final updatedDressType = dressTypes.firstWhere(
                    (dress) => dress['id'] == item['dressTypeId'],
                    orElse: () => {},
                  );
                  if (updatedDressType.isNotEmpty) {
                    dressType.addAll(updatedDressType);
                  }
                });
              });
            }

            final selectedDressTypeName =
                dressType.isNotEmpty ? dressType['name'] : 'Unknown';
            print(
                "Updated dropdownDressController with selected dress type: $selectedDressTypeName ::: $dressType");

            return OrderItem(
              selectedDressType: dressType.isNotEmpty ? dressType : null,
              selectedDressTypeId: item['dressTypeId'],
              selectedOrderType: selectedOrderType,
              orderItemId: widget.orderId != null ? item['orderItemId'] ?? 0 : null,
              orderItemMeasurementId: widget.orderId != null ? item['orderItemMeasurementId'] ?? 0 : null,
              orderItemPatternId: widget.orderId != null ? item['orderItemPatternId'] ?? 0 : null,
              measurements: (item['measurement'] as List<dynamic>?)
                      ?.expand<Map<String, dynamic>>((m) {
                    return (m as Map<String, dynamic>)
                        .entries
                        .where((entry) =>
                            entry.key != '_id' &&
                            entry.key != 'dressTypeId' &&
                            entry.key != 'customerId' &&
                            entry.key != 'orderId' &&
                            entry.key != 'orderItemId' &&
                            entry.key != 'orderItemMeasurementId' &&
                            entry.key != 'owner' &&
                            entry.key != 'createdAt' &&
                            entry.key != 'updatedAt')
                        .map((entry) {
                      print(
                          'Raw measurement value for ${entry.key}: ${entry.value}');
                      final value = entry.value?.toString() ?? '0';
                      final controller = TextEditingController(text: value);
                      print(
                          'Created controller for ${entry.key} with value: ${controller.text}, hashCode: ${controller.hashCode}');
                      return {
                        'name': entry.key,
                        'dressTypeMeasurementId': m['orderItemMeasurementId'] ?? 0,
                        'value': controller,
                      };
                    });
                  }).toList() ??
                  [],
              selectedPatterns: (item['pattern'] as List<dynamic>?)
                      ?.expand<Map<String, dynamic>>((pattern) {
                    return (pattern['patterns'] as List<dynamic>?)?.map((p) {
                          print(
                              'Pattern: category=${p['category']}, name=${p['name']}');
                          return {
                            'orderItemPatternId': p['_id'] != null && widget.orderId != null
                                ? item['orderItemPatternId'] ?? 0
                                : 0,
                            'category': p['category'] ?? 'Unknown',
                            'name': p['name'] is List
                                ? p['name']
                                : [p['name'].toString()],
                          };
                        }) ??
                        [];
                  }).toList() ??
                  [],
              specialInstructions: TextEditingController(
                  text: item['special_instructions'] ?? ''),
              deliveryDate: TextEditingController(
                text: item['deliveryDate'] ??
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
              ),
              originalCost:
                  TextEditingController(text: item['amount']?.toString() ?? ''),
              dropdownDressController:
                  TextEditingController(text: selectedDressTypeName),
            );
          }).toList();

          additionalCostControllers =
              (order['additionalCosts'] as List<dynamic>?)?.map((cost) {
                    return {
                      'description':
                          TextEditingController(text: cost['description'] ?? ''),
                      'amount': TextEditingController(
                          text: cost['amount']?.toString() ?? ''),
                    };
                  }).toList() ??
                  [
                    {
                      'description': TextEditingController(),
                      'amount': TextEditingController(),
                    }
                  ];

          isLoading = false;
        });

        for (var item in orderItems) {
          if (item.selectedDressTypeId != null) {
            final fetchedPatterns = await fetchPatterns(item.selectedDressTypeId);
            if (!mounted) return;

            final existingPatterns = item.selectedPatterns;
            final mergedPatterns = <Map<String, dynamic>>[];

            for (var pattern in existingPatterns) {
              mergedPatterns.add(pattern);
            }

            for (var fetchedPattern in fetchedPatterns) {
              final category =
                  fetchedPattern['category']?.toString() ?? 'Unknown';
              final exists =
                  mergedPatterns.any((p) => p['category'] == category);
              if (!exists) {
                mergedPatterns.add(fetchedPattern);
              }
            }

            setState(() {
              item.selectedPatterns = mergedPatterns;
              print(
                  "Updated selectedPatterns for item: ${item.selectedPatterns}");
            });
          }
        }

        for (var item in orderItems) {
          if (item.selectedDressTypeId != null) {
            await fetchMeasurements(item.selectedDressTypeId, item);
          }
        }
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No order data found in response')),
        );
      }
    } else {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid response format')),
      );
    }
  } catch (e) {
    hideLoader(context);
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    print("Error fetching order details: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load order: $e')),
    );
  }
}

  String _mapOrderType(int? typeId) {
    switch (typeId) {
      case 1:
        return "Stitching";
      case 2:
        return "Alter";
      case 3:
        return "Material";
      default:
        return "Stitching";
    }
  }

  double get totalAdditionalCost {
    return additionalCostControllers.fold(0.0, (sum, item) {
      final value = double.tryParse(item['amount']?.text ?? '') ?? 0.0;
      return sum + value;
    });
  }

  double get totalOriginalCost {
    return orderItems.fold(0.0, (sum, item) {
      final controller = item.originalCost;
      final amount = double.tryParse(controller?.text ?? "") ?? 0.0;
      return sum + amount;
    });
  }

  double get totalCourierCost {
    return double.tryParse(courierController.text) ?? 0.0;
  }

  double calculateTotalCost() {
    final courierAmount = double.tryParse(courierController.text) ?? 0.0;
    final total = totalOriginalCost + totalAdditionalCost + courierAmount;
    totalCostController.text = total.toStringAsFixed(2);
    return total;
  }

  double get calculateTotalCosts {
    final courierAmount = double.tryParse(courierController.text) ?? 0.0;
    final discountAmount = double.tryParse(discountController.text) ?? 0.0;
    final total = totalOriginalCost +
        totalAdditionalCost +
        courierAmount -
        discountAmount;
    totalCostController.text = total.toStringAsFixed(2);
    return total;
  }

  Future<void> _pickFromCamera() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Open Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Select from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _recordAudio() {
    print("🎙 Start Recording Audio...");
    // TODO: Implement audio recording logic
  }

  Future<void> _navigateToCreateCustomer() async {
    print('🚀 Navigating to create customer page...');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Customerinfo(shouldNavigateBack: true),
      ),
    );
    
    print('📥 Received result from customer creation: $result');
    print('📥 Result type: ${result.runtimeType}');
    
    if (result != null && result is Map<String, dynamic>) {
      // New customer was created, add it to the current list and select it
      final newCustomer = result as Map<String, dynamic>;
      print('✅ Processing new customer: $newCustomer');
      
      setState(() {
        // Add new customer to the beginning of the list
        customers.insert(0, newCustomer);
        selectedCustomer = newCustomer;
        selectedCustomerId = newCustomer['customerId'];
        dropdownCustomerController.text = newCustomer['name'];
      });
      
      // Show success message
      CustomSnackbar.showSnackbar(
        context,
        'Customer "${newCustomer['name']}" created and selected successfully!',
        duration: Duration(seconds: 3),
      );
    } else {
      print('❌ No customer data received or invalid format');
    }
  }

 void onHandleSaveOrder() async {
  int? shopId = GlobalVariables.shopIdGet;
  int? branchId = GlobalVariables.branchId;
  int? userId = GlobalVariables.userId;

  List<Map<String, dynamic>> items = orderItems.map((item) {
    // Extract orderItemMeasurementId from measurements (only for update)
    int? orderItemMeasurementId = widget.orderId != null ? item.orderItemMeasurementId : null;

    // Dynamically construct Measurement object based on available measurements
    Map<String, dynamic> measurementMap = {};
    
    // Include orderItemMeasurementId only for update
    if (widget.orderId != null && orderItemMeasurementId != null) {
      measurementMap["orderItemMeasurementId"] = orderItemMeasurementId;
    }

    // Add only the measurement fields that exist in item.measurements
    if (item.measurements.isNotEmpty) {
      for (var m in item.measurements) {
        String key = m['name'].toString().toLowerCase().replaceAll(' ', '_');
        measurementMap[key] = double.tryParse(m['value'].text) ?? 0.0;
      }
    }

    // Construct the Item map
    Map<String, dynamic> itemMap = {
      if(widget.orderId != null) "orderItemId": item.orderItemId ?? null,
      "dressTypeId": item.selectedDressTypeId,
      "Measurement": measurementMap,
      "Pattern": item.selectedPatterns.isNotEmpty
          ? item.selectedPatterns.map((pattern) {
              Map<String, dynamic> patternMap = {
                "category": pattern['category'] ?? 'Unknown',
                "name": pattern['name'] is List
                    ? pattern['name']
                    : [pattern['name'].toString()],
              };
              // Include orderItemPatternId only for update
              if (widget.orderId != null) {
                patternMap["orderItemPatternId"] = item.orderItemPatternId;
              }
              return patternMap;
            }).toList()
          : [
              {
                "category": "Unknown",
                "name": ["None"]
              }
            ],
      "special_instructions": item.specialInstructions?.text ?? "",
      "recording": "",
      "videoLink": "", // Not implemented yet
      "pictures": _selectedImages.map((file) => file.path).toList(),
      "delivery_date": DateFormat("yyyy-MM-dd").format(
        DateTime.tryParse(item.deliveryDate?.text ?? "") ?? DateTime.now(),
      ),
      "amount": double.tryParse(item.originalCost?.text ?? "0") ?? 0.0,
      "status": "received",
      "owner": userId.toString(),
    };

    // Conditionally add orderItemId if updating an existing order
    if (widget.orderId != null) {
      itemMap["orderItemId"] = item.orderItemId ?? 0;
    }

    return itemMap;
  }).toList();

  int? selectedOrderTypeId;
  if (selectedOrderType == "Stitching") {
    selectedOrderTypeId = 1;
  } else if (selectedOrderType == "Alter") {
    selectedOrderTypeId = 2;
  } else if (selectedOrderType == "Material") {
    selectedOrderTypeId = 3;
  }

  final payload = {
    "Order": {
      "shop_id": shopId,
      "branchId": branchId,
      "customerId": selectedCustomerId,
      "stitchingType": selectedOrderTypeId,
      "noOfMeasurementDresses": orderItems.length,
      "quantity": orderItems.length,
      "urgent": isUrgent,
      "status": "received",
      "estimationCost": double.tryParse(totalCostController.text) ?? 0.0,
      "advancereceived": double.tryParse(advanceAmountController.text) ?? 0.0,
      "advanceReceivedDate": DateFormat("yyyy-MM-dd").format(DateTime.now()),
      "gst": isGstChecked,
      "gst_amount": isGstChecked
          ? (double.tryParse(gstController.text) ?? 0.0)
          : 0.0,
      "Courier": isCourierChecked,
      "courierCharge": double.tryParse(courierController.text) ?? 0.0,
      "discount": double.tryParse(discountController.text) ?? 0.0,
      "owner": userId.toString(),
    },
    "Item": items,
  };

  print('Payload => $payload');

  try {
    var response;
    if (widget.orderId != null) {
      final url = "${Urls.ordersSave}/$shopId/${widget.orderId}";
      response = await ApiService().put(url, data: payload, context);
    } else {
      response = await ApiService().post(Urls.ordersSave, data: payload, context);
    }

    if (!mounted) return;

    if (response.data != null && response.data is Map<String, dynamic>) {
      final responseData = response.data as Map<String, dynamic>;
      final message = responseData['message'] ?? 'Order Updated Successfully';

      CustomSnackbar.showSnackbar(
        context,
        message,
        duration: Duration(seconds: 2),
      );
      if(widget.orderId == null){
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.homeUi);
      }
    } else {
      CustomSnackbar.showSnackbar(
        context,
        'Failed to update order',
        duration: Duration(seconds: 2),
      );
    }
  } catch (e) {
    print('Error: $e');
    CustomSnackbar.showSnackbar(
      context,
      'Failed to save order: $e',
      duration: Duration(seconds: 2),
    );
  }
}

  void handlePatternModal(BuildContext context, OrderItem orderItem) async {
    // Fetch patterns for the selected dress type
    final patterns = await fetchPatterns(orderItem.selectedDressTypeId);
    print('Fetched patterns: $patterns');
    if (patterns.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        "No patterns available for this dress type",
        duration: Duration(seconds: 2),
      );
      return;
    }

    // Pass patterns and selectedPatterns to PatternSelectionmodal
    final result = await showDialog(
      context: context,
      builder: (context) => PatternSelectionmodal(
        patternsList: {"patterns": patterns},
        selectedPatterns: orderItem.selectedPatterns,
      ),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        orderItem.selectedPatterns = result.map((item) {
          return {
            'category': item['category'],
            'name': (item['name'] as List).cast<String>(),
          };
        }).toList();
      });

      print('Updated Selected Patterns: ${orderItem.selectedPatterns}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(
          title: widget.orderId != null
              ? Textstring().updateOrder
              : Textstring().createorder),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: ColorPalatte.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading order form...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Customer', style: Createorderstyle.selecteCustomer),
                      ),
                      IconButton(
                        onPressed: _navigateToCreateCustomer,
                        icon: Icon(Icons.person_add, color: ColorPalatte.primary),
                        tooltip: 'Add New Customer',
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  _buildDropdownCustomer(
                    "Select Customer",
                    selectedCustomer,
                    customers,
                    (selectedValue) {
                      setState(() {
                        selectedCustomer = selectedValue;
                        selectedCustomerId = selectedValue['customerId'];
                        dropdownCustomerController.text = selectedValue['name'];
                        dressTypes = [];
                        fetchDressTypeData(
                          pageNumber: 1,
                          pageSize: pageSize,
                          existingDressTypes: [],
                        ).then((newDressTypes) {
                          setState(() {
                            dressTypes = newDressTypes;
                          });
                        });
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Order Type', style: Createorderstyle.selecteCustomer),
                  Row(
                    children: ["Stitching", "Alter", "Material"].map((type) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: type,
                            groupValue: selectedOrderType,
                            activeColor: ColorPalatte.primary,
                            onChanged: (value) {
                              setState(() {
                                selectedOrderType = value!;
                              });
                            },
                          ),
                          Text(type, style: Createorderstyle.radioBtnText),
                          const SizedBox(width: 5),
                        ],
                      );
                    }).toList(),
                  ),
                  ...orderItems.asMap().entries.map((entry) {
                    int index = entry.key;
                    OrderItem item = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!item.isExpanded) SizedBox(height: 10),
                        Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: Colors.grey.shade400, width: 0.2),
                          ),
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 2),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                for (var i = 0; i < orderItems.length; i++) {
                                  orderItems[i].isExpanded = false;
                                }
                                item.isExpanded = !item.isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Item ${index + 1}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    item.isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 28,
                                    color: Colors.grey[700],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 3),
                        if (item.isExpanded)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Text('Dress Type',
                                  style: Createorderstyle.selecteCustomer),
                              SizedBox(height: 10),
                              _buildDropdown(
                                "Select Dress Type",
                                item.selectedDressType,
                                dressTypes,
                                (selectedValue) {
                                  setState(() {
                                    item.selectedDressType = selectedValue;
                                    item.selectedDressTypeId =
                                        selectedValue?['id'];
                                    dropdownDressController.text =
                                        selectedValue?['name'] ?? '';
                                    item.measurements = [];
                                    item.selectedPatterns = [];
                                    fetchMeasurements(
                                        item.selectedDressTypeId, item);
                                  });
                                },
                              ),
                              if (item.selectedDressTypeId != null) ...[
                                SizedBox(height: 10),
                                Text('Measurements'),
                                SizedBox(height: 10),
                                item.measurements.isNotEmpty
                                    ? _buildMeasurementGrid(item)
                                    : Text(
                                        "No measurements available for this dress type."),
                                SizedBox(height: 10),
                                if (item.selectedPatterns.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text('Selected Patterns'),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        item.selectedPatterns.map((pattern) {
                                      final category =
                                          pattern['category'] ?? 'Unknown';
                                      final names = pattern['name'];
                                      final nameList = names is List
                                          ? names
                                          : names is String
                                              ? [names]
                                              : [];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          "$category: ${nameList.join(', ')}",
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                SizedBox(height: 10),
                                _buildButton('Add Pattern', onPressed: () {
                                  handlePatternModal(context, item);
                                }),
                              ],
                              SizedBox(height: 10),
                              Text('Special Instructions'),
                              SizedBox(height: 10),
                              _buildTextField(
                                "Add any special instructions here...",
                                minLines: 4,
                                controller: item.specialInstructions,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildButton("🎙 Record Audio",
                                          onPressed: _recordAudio)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _buildButton("📷 Take Picture",
                                          onPressed: _showImagePickerOptions)),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomDatePicker(
                                      label: Textstring().deliveryDate,
                                      controller: item.deliveryDate!,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Checkbox(
                                    value: isUrgent,
                                    onChanged: (value) {
                                      setState(() {
                                        isUrgent = value!;
                                      });
                                    },
                                  ),
                                  const Text("Urgent"),
                                ],
                              ),
                              Text('Cost'),
                              SizedBox(height: 5),
                              _buildTextField(
                                "Enter cost",
                                keyboardType: TextInputType.number,
                                controller: item.originalCost,
                              ),
                            ],
                          ),
                      ],
                    );
                  }),
                  SizedBox(height: 15),
                  _buildButton("+ Add Another Item", onPressed: () {
                    setState(() {
                      for (var item in orderItems) {
                        item.isExpanded = false;
                      }
                      orderItems.add(OrderItem(isExpanded: true));
                    });
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Additional Cost",
                          style: Createorderstyle.selecteCustomer),
                      _buildIconButtonCost(Icons.add_circle, () {
                        setState(() {
                          additionalCostControllers.add({
                            'description': TextEditingController(),
                            'amount': TextEditingController(),
                          });
                        });
                      }),
                    ],
                  ),
                  _buildAdditionalCostFields(),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isCourierChecked,
                            activeColor: Colors.brown,
                            onChanged: (value) {
                              setState(() {
                                isCourierChecked = value!;
                              });
                            },
                          ),
                          const Text("Courier"),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: courierController,
                              enabled: isCourierChecked,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter Courier amount",
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: isGstChecked,
                            activeColor: Colors.brown,
                            onChanged: (value) {
                              setState(() {
                                isGstChecked = value!;
                              });
                            },
                          ),
                          const Text("GST"),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: gstController,
                              enabled: isGstChecked,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter GST number",
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Quantity", style: TextStyle(fontSize: 16)),
                      Text(orderItems.length.toString(),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Discount",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          width: 100, // Set to desired width
                          child: _buildTextField(
                            "INR",
                            controller: discountController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Cost",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          widget.orderId != null
                              ? "₹ ${totalCostController.text}"
                              : "₹ ${calculateTotalCosts.toDouble().toString()}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Advance'),
                  SizedBox(height: 5),
                  _buildTextField(
                    "Enter advance amount",
                    controller: advanceAmountController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildButton(
                    widget.orderId != null
                        ? Textstring().updateOrder
                        : Textstring().saveOrder,
                    onPressed: onHandleSaveOrder,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdownCustomer<T>(
    String hint,
    T? value,
    List<T> items,
    void Function(T) onChanged,
  ) {
    return InkWell(
      onTap: () {
        _showCustomerDialog(
          context,
          hint,
          value,
          items,
          (selectedItem) {
            onChanged(selectedItem);
          },
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
        ),
        child: Text(
          value != null &&
                  value is Map<String, dynamic> &&
                  value['name'] != null
              ? value['name'].toString()
              : dropdownCustomerController.text.isNotEmpty
                  ? dropdownCustomerController.text
                  : hint,
          style: TextStyle(
            color: (value != null &&
                        value is Map<String, dynamic> &&
                        value['name'] != null) ||
                    dropdownCustomerController.text.isNotEmpty
                ? Colors.black
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
    String hint,
    T? value,
    List<T> items,
    void Function(T) onChanged,
  ) {
    return InkWell(
      onTap: () {
        _showDressTypeDialog(
          context,
          hint,
          value,
          items,
          (selectedItem) {
            onChanged(selectedItem);
            if (selectedItem != null && selectedItem is Map<String, dynamic>) {
              setState(() {
                final selectedMap = selectedItem as Map<String, dynamic>;
                if (!dressTypes
                    .any((item) => item['id'] == selectedMap['id'])) {
                  dressTypes = [...dressTypes, selectedMap];
                }
                dropdownDressController.text = selectedMap['name'] ?? hint;
              });
            }
          },
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(
          value != null &&
                  value is Map<String, dynamic> &&
                  value['name'] != null
              ? value['name'].toString()
              : dropdownDressController.text.isNotEmpty
                  ? dropdownDressController.text
                  : hint,
          style: TextStyle(
            color: (value != null &&
                        value is Map<String, dynamic> &&
                        value['name'] != null) ||
                    dropdownDressController.text.isNotEmpty
                ? Colors.black
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showCustomerDialog<T>(
    BuildContext context,
    String hint,
    T? selectedValue,
    List<T> items,
    void Function(T) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _CustomerDialog<T>(
          hint: hint,
          selectedValue: selectedValue,
          onChanged: onChanged,
          customers: customers,
        );
      },
    );
  }

  void _showDressTypeDialog<T>(
    BuildContext context,
    String hint,
    T? selectedValue,
    List<T> items,
    void Function(T) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _DressTypeDialog<T>(
          hint: hint,
          selectedValue: selectedValue,
          onChanged: onChanged,
          initialDressTypes: dressTypes, // Pass main screen's dressTypes
        );
      },
    );
  }

  Widget _buildTextField(
    String hint, {
    IconData? icon,
    int? maxline,
    int? length,
    int minLines = 1,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: Createorderstyle.cuttingValuesText,
      minLines: minLines,
      maxLines: maxline,
      maxLength: length,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorPalatte.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorPalatte.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorPalatte.primary, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Widget _buildMeasurementGrid(OrderItem item) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: item.measurements.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final measurement = item.measurements[index];
        final controller = measurement['value'] as TextEditingController;
        print('Rendering TextField for ${measurement['name']}: '
            'controller.text=${controller.text}, '
            'hashCode=${controller.hashCode}');
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: measurement['name'],
            hintText: "Enter value",
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      },
    );
  }

  Widget _buildButton(String text, {VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalatte.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(text, style: Createorderstyle.buttonsText),
      ),
    );
  }

  Widget _buildAdditionalCostFields() {
    return Column(
      children: additionalCostControllers.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildTextField("Item description",
                    controller: item['description']),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildTextField("Amount",
                    controller: item['amount'],
                    keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 10),
              if (index != 0)
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      additionalCostControllers.removeAt(index);
                    });
                  },
                )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconButtonCost(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorPalatte.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class Measurement {
  final String name;
  final int dressTypeMeasurementId;
  final TextEditingController controller;

  Measurement({
    required this.name,
    required this.dressTypeMeasurementId,
    required this.controller,
  });
}

class Pattern {
  final String id;
  final String category;
  final String name;
  final String selection;

  Pattern({
    required this.id,
    required this.category,
    required this.name,
    this.selection = 'multiple',
  });

  Map<String, dynamic> toMap() => {
        '_id': id,
        'category': category,
        'name': name,
        'selection': selection,
      };
}

class OrderItem {
  Map<String, dynamic>? selectedDressType;
  int? selectedDressTypeId;
  String selectedOrderType;
  bool showPatternGrid;
  List<Map<String, dynamic>> measurements;
  bool isExpanded;
  TextEditingController? originalCost;
  TextEditingController? specialInstructions;
  TextEditingController? deliveryDate;
  List<Map<String, dynamic>> selectedPatterns;
  TextEditingController dropdownDressController;
  int? orderItemId;
  int? orderItemMeasurementId;
  int? orderItemPatternId;

  OrderItem({
    this.selectedDressType,
    this.selectedDressTypeId,
    this.selectedOrderType = "Stitching",
    this.showPatternGrid = false,
    this.measurements = const [],
    this.selectedPatterns = const [],
    this.isExpanded = true,
    TextEditingController? deliveryDate,
    TextEditingController? originalCost,
    TextEditingController? specialInstructions,
    TextEditingController? dropdownDressController,
    this.orderItemId,
    this.orderItemMeasurementId,
    this.orderItemPatternId,
  })  : originalCost = originalCost ?? TextEditingController(),
        specialInstructions = specialInstructions ?? TextEditingController(),
        dropdownDressController = dropdownDressController ??
            TextEditingController(text: "Select Dress Type"),
        deliveryDate = deliveryDate ??
            TextEditingController(
                text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
}

class _CustomerDialog<T> extends StatefulWidget {
  final String hint;
  final T? selectedValue;
  final void Function(T) onChanged;
  final List<Map<String, dynamic>> customers;

  const _CustomerDialog({
    required this.hint,
    required this.selectedValue,
    required this.onChanged,
    required this.customers,
  });

  @override
  _CustomerDialogState<T> createState() => _CustomerDialogState<T>();
}

class _CustomerDialogState<T> extends State<_CustomerDialog<T>> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredCustomers = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  int _pageNumber = 1;
  final int _pageSize = 15;
  bool _isLoading = false;
  bool _hasMoreData = true;
  List<Map<String, dynamic>> _allCustomers = [];

  @override
  void initState() {
    super.initState();
    _allCustomers = List.from(widget.customers);
    _filteredCustomers = List.from(_allCustomers);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_debounce?.isActive ?? false) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50 &&
        _hasMoreData &&
        !_isLoading) {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _loadMoreCustomers();
      });
    }
  }

  Future<void> _loadMoreCustomers() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });

    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final String requestUrl = "${Urls.customer}/$shopId?pageNumber=${_pageNumber + 1}&pageSize=$_pageSize";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data is Map<String, dynamic>) {
        List<dynamic> customerData = response.data['data'];
        List<Map<String, dynamic>> newCustomers = customerData.cast<Map<String, dynamic>>();
        
        setState(() {
          _allCustomers.addAll(newCustomers);
          _pageNumber++;
          _hasMoreData = newCustomers.length == _pageSize;
          _isLoading = false;
        });
        
        _filterCustomers();
      } else {
        setState(() {
          _hasMoreData = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCustomers = List.from(_allCustomers);
      } else {
        _filteredCustomers = _allCustomers.where((customer) {
          final name = customer['name']?.toString().toLowerCase() ?? '';
          final mobile = customer['mobile']?.toString() ?? '';
          final searchLower = _searchQuery.toLowerCase();
          
          return name.contains(searchLower) || mobile.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.hint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or mobile number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterCustomers();
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredCustomers.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'No customers available'
                                : 'No customers found matching "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.grey.shade600
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredCustomers.length + (_hasMoreData || _isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredCustomers.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }
                        
                        final customer = _filteredCustomers[index];
                        final isSelected = customer == widget.selectedValue;
                        final name = customer['name']?.toString() ?? 'Unknown';
                        final mobile = customer['mobile']?.toString() ?? '';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ColorPalatte.primary,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: isSelected
                                  ? ColorPalatte.primary
                                  : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: mobile.isNotEmpty 
                              ? Text(
                                  mobile,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          onTap: () {
                            widget.onChanged(customer as T);
                            Navigator.pop(context);
                          },
                          selected: isSelected,
                          selectedTileColor: Colors.grey[100],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: ColorPalatte.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DressTypeDialog<T> extends StatefulWidget {
  final String hint;
  final T? selectedValue;
  final void Function(T) onChanged;
  final List<Map<String, dynamic>> initialDressTypes;

  const _DressTypeDialog({
    required this.hint,
    required this.selectedValue,
    required this.onChanged,
    required this.initialDressTypes,
  });

  @override
  _DressTypeDialogState<T> createState() => _DressTypeDialogState<T>();
}

class _DressTypeDialogState<T> extends State<_DressTypeDialog<T>> {
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _searchQuery = '';
  List<Map<String, dynamic>> _dressTypes = [];
  int _pageNumber = 1;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dressTypes = List.from(widget.initialDressTypes);
    _fetchDressTypes(initialFetch: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_debounce?.isActive ?? false) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50 &&
        _hasMoreData &&
        !_isLoading) {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _pageNumber++;
          _isLoading = true;
        });
        _fetchDressTypes();
      });
    }
  }

  Future<void> _fetchDressTypes({bool initialFetch = false}) async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          "Shop ID is missing",
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    final String requestUrl =
        "${Urls.addDress}/$id?pageNumber=$_pageNumber&pageSize=$_pageSize";
    try {
      final response = await ApiService().get(requestUrl, context);
      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedData = response.data['data'];
        List<Map<String, dynamic>> newDressTypes = fetchedData.map((dress) {
          return {
            "id": dress['dressTypeId'],
            "name": dress['name'],
          };
        }).toList();

        if (mounted) {
          setState(() {
            _dressTypes = initialFetch
                ? newDressTypes
                : [..._dressTypes, ...newDressTypes];
            _hasMoreData = newDressTypes.length == _pageSize;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          CustomSnackbar.showSnackbar(
            context,
            'No dress types found',
            duration: const Duration(seconds: 2),
          );
          setState(() {
            _dressTypes = [];
            _hasMoreData = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Failed to load dress types',
          duration: const Duration(seconds: 2),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _dressTypes.where((item) {
      final name = item['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hint,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search dress types...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredItems.isEmpty && !_isLoading
                  ? const Center(child: Text('No dress types found'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredItems.length +
                          (_hasMoreData || _isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredItems.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }
                        final item = filteredItems[index];
                        final isSelected = item == widget.selectedValue;
                        return ListTile(
                          title: Text(
                            item['name'].toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? ColorPalatte.primary
                                  : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            widget.onChanged(item as T);
                            Navigator.pop(context);
                          },
                          selected: isSelected,
                          selectedTileColor: Colors.grey[100],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: ColorPalatte.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
