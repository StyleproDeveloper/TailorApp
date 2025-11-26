import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' show Dio, DioException, FormData, MultipartFile, Response, Options, DioMediaType;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
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
  List<Map<String, dynamic>> additionalCostControllers = [];
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  OrderItem? _currentRecordingItem;
  Timer? _recordingTimer;
  int _recordingDuration = 0; // Duration in seconds
  final ScrollController _scrollController = ScrollController();
  int pageNumber = 1;
  final int pageSize = 10;
  bool hasMoreData = true;
  Timer? _debounce;
  bool _isDisposed = false;
  
  // Order status management
  String currentOrderStatus = "received";
  final List<Map<String, dynamic>> orderStatuses = [
    {
      'key': 'received',
      'label': 'Received',
      'description': 'Order received and confirmed',
      'icon': Icons.inbox,
      'color': Colors.blue,
    },
    {
      'key': 'in_progress',
      'label': 'In Progress',
      'description': 'Work has started on the order',
      'icon': Icons.work,
      'color': Colors.orange,
    },
    {
      'key': 'completed',
      'label': 'Completed',
      'description': 'Order is ready for delivery',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'key': 'delivered',
      'label': 'Delivered',
      'description': 'Order has been delivered to customer',
      'icon': Icons.local_shipping,
      'color': Colors.purple,
    },
  ];
  
  // Cache for customers to avoid repeated API calls
  static Map<String, List<Map<String, dynamic>>> _customerCache = {};
  static DateTime? _lastCacheTime;

  bool _permissionChecked = false;
  bool _hasAccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Check permissions IMMEDIATELY - don't wait for post frame callback
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    print('🔍 CreateOrderScreen - Starting permission check');
    // Force reload permissions with timeout
    try {
      await GlobalVariables.loadShopId().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ loadShopId timed out, continuing anyway');
        },
      );
    } catch (e) {
      print('⚠️ Error loading shop ID: $e, continuing anyway');
    }
    
    final args = ModalRoute.of(context)?.settings.arguments;
    final isEditMode = args != null || widget.orderId != null;
    
    print('🔍 CreateOrderScreen - Checking permissions');
    print('🔍 isEditMode: $isEditMode');
    print('🔍 Current permissions: ${GlobalVariables.permissions}');
    print('🔍 permissions.isEmpty: ${GlobalVariables.permissions.isEmpty}');
    print('🔍 permissions count: ${GlobalVariables.permissions.length}');
    print('🔍 hasPermission(createOrder): ${GlobalVariables.hasPermission('createOrder')}');
    print('🔍 hasPermission(editOrder): ${GlobalVariables.hasPermission('editOrder')}');
    
    bool hasPermission = false;
    String errorMessage = '';
    
    if (isEditMode) {
      // Editing existing order - requires editOrder permission
      hasPermission = GlobalVariables.hasPermission('editOrder');
      errorMessage = 'You do not have permission to edit orders';
    } else {
      // Creating new order - requires createOrder permission
      hasPermission = GlobalVariables.hasPermission('createOrder');
      errorMessage = 'You do not have permission to create orders';
    }
    
    if (!hasPermission) {
      print('❌ BLOCKING: No permission - $errorMessage');
      if (mounted) {
        setState(() {
          _permissionChecked = true;
          _hasAccess = false;
          _errorMessage = errorMessage;
        });
        // Pop after a brief delay to show error screen
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.pop(context);
            CustomSnackbar.showSnackbar(
              context,
              errorMessage,
              duration: Duration(seconds: 3),
            );
          }
        });
      }
      return;
    }
    
    print('✅ Permission check passed, allowing access');
    
    // Initialize additional cost controllers
    final initialCost = {
      'description': TextEditingController(),
      'amount': TextEditingController(),
    };
    // Add listener to the initial cost controller
    initialCost['amount']?.addListener(_updateTotalCost);
    additionalCostControllers.add(initialCost);

    // Add listeners to cost controllers for automatic total calculation
    _addCostListeners();

    // Don't show UI until permission is checked
    setState(() {
      _permissionChecked = true;
      _hasAccess = true;
      isLoading = true; // Keep loading until permission check
    });

    // Fetch data in background after permission check
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDataInBackground();
    });
  }
  
  void _addCostListeners() {
    // Listen to courier cost changes
    courierController.addListener(_updateTotalCost);
    
    // Listen to discount changes
    discountController.addListener(_updateTotalCost);
    
    // Advance amount is now handled in payment section, not in order creation
    // advanceAmountController.addListener(_updateTotalCost);
    
    // Listen to additional cost changes
    for (var cost in additionalCostControllers) {
      cost['amount']?.addListener(_updateTotalCost);
    }
  }

  void _updateTotalCost() {
    if (mounted) {
      setState(() {
        calculateTotalCosts; // This will update the totalCostController
      });
    }
  }

  Future<void> _loadDataInBackground() async {
    try {
      // Handle orderId if exists - load all customers first for edit mode
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        setState(() {
          widget.orderId = args;
        });
        // For edit mode, ensure shop ID is available
        int? shopId = GlobalVariables.shopIdGet;
        if (shopId == null) {
          print('⚠️ Shop ID is null, cannot load order data');
          if (mounted) {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Shop ID is missing. Cannot load order.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
        // For edit mode, load all customers first with larger page size to ensure we get the customer
        await _fetchAllCustomers(shopId, pageNumber: 1, pageSize: 1000);
        // Load dress types in background (non-blocking) to avoid blocking order processing
        _loadDressTypesInBackground();
        await fetchProductDetail();
      } else {
        // For create mode, load only initial customers for faster loading
        print('📋 Create mode: Loading initial customers...');
        // Add timeout to prevent infinite loading
        try {
          await _fetchInitialCustomers().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ _fetchInitialCustomers timed out after 10 seconds');
              if (mounted) {
                setState(() {
                  customers = [];
                });
              }
            },
          );
          print('✅ _fetchInitialCustomers completed');
        } catch (e) {
          print('❌ Error in _fetchInitialCustomers: $e');
          if (mounted) {
            setState(() {
              customers = [];
            });
          }
        }
        // Load dress types in background (non-blocking)
        _loadDressTypesInBackground();
        // Always set loading to false after data is loaded (or failed)
        print('✅ Setting isLoading = false');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading data in background: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDressTypesInBackground() async {
    try {
      await fetchDressTypeData(
        pageNumber: 1,
        pageSize: 20,
        existingDressTypes: [],
        initialFetch: true,
      );
    } catch (e) {
      print('Error loading dress types: $e');
      // Don't let dress type loading failure break the app
      if (mounted) {
        setState(() {
          dressTypes = []; // Initialize empty list to prevent null errors
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchSpecificDressType(int dressTypeId) async {
    try {
      int? shopId = GlobalVariables.shopIdGet;
      if (shopId == null) return null;

      // Search for the specific dress type
      final String requestUrl = "${Urls.addDress}/$shopId?pageNumber=1&pageSize=1000";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        List<dynamic> allDressTypes = response.data['data'];
        final foundDressType = allDressTypes.firstWhere(
          (dressType) => dressType['dressTypeId'] == dressTypeId,
          orElse: () => null,
        );
        
        if (foundDressType != null) {
          print('✅ Specific dress type fetched: ${foundDressType['name']} (ID: $dressTypeId)');
          // Add to dress types list if not already there
          if (!dressTypes.any((d) => d['dressTypeId'] == dressTypeId)) {
            setState(() {
              dressTypes.insert(0, foundDressType);
            });
          }
          return foundDressType;
        } else {
          print('❌ Dress type ID $dressTypeId not found in any list');
        }
      }
    } catch (e) {
      print('❌ Error fetching specific dress type: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Stop and dispose audio recorder
    _recordingTimer?.cancel();
    if (_isRecording) {
      _audioRecorder.stop().catchError((e) => print('Error stopping recorder on dispose: $e'));
    }
    _audioRecorder.dispose();
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
      print("⚠️ Shop ID is missing in _fetchInitialCustomers");
      // Don't return early - set customers to empty and let the caller handle it
      if (mounted) {
        setState(() {
          customers = [];
        });
      }
      return;
    }

    String cacheKey = "customers_$id";
    
    // Check cache first (valid for 5 minutes)
    if (_customerCache.containsKey(cacheKey) && 
        _lastCacheTime != null && 
        DateTime.now().difference(_lastCacheTime!).inMinutes < 5) {
      if (mounted) {
        setState(() {
          customers = _customerCache[cacheKey] ?? [];
        });
      }
      return;
    }

    // Fetch only first 5 customers for ultra-fast initial load
    try {
      final String requestUrl = "${Urls.customer}/$id?pageNumber=1&pageSize=5";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data is Map<String, dynamic>) {
        List<dynamic> customerData = response.data['data'];
        List<Map<String, dynamic>> customerList = customerData.cast<Map<String, dynamic>>();
        
        // Update cache
        _customerCache[cacheKey] = customerList;
        _lastCacheTime = DateTime.now();
        
        if (mounted) {
          setState(() {
            customers = customerList;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            customers = [];
          });
        }
      }
    } catch (e) {
      print('Error fetching initial customers: $e');
      if (mounted) {
        setState(() {
          customers = [];
        });
      }
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

  Future<void> _fetchSpecificCustomer(int customerId) async {
    try {
      // Validate customerId is not null or 0
      if (customerId == null || customerId == 0) {
        print('⚠️ Cannot fetch customer: Invalid customerId ($customerId)');
        if (mounted) {
          setState(() {
            selectedCustomerId = null;
            selectedCustomer = null;
            dropdownCustomerController.text = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid customer ID. Please select a customer.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      int? shopId = GlobalVariables.shopIdGet;
      if (shopId == null) {
        print('⚠️ Cannot fetch customer: Shop ID is null');
        return;
      }

      // Search for the specific customer
      final String requestUrl = "${Urls.customer}/$shopId?pageNumber=1&pageSize=1000&searchKeyword=";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        List<dynamic> allCustomers = response.data['data'];
        final foundCustomer = allCustomers.firstWhere(
          (customer) => customer['customerId'] == customerId,
          orElse: () => null,
        );
        
        if (foundCustomer != null) {
          setState(() {
            selectedCustomer = foundCustomer;
            selectedCustomerId = customerId; // Ensure it's set
            dropdownCustomerController.text = foundCustomer['name'] ?? '';
            // Add to customers list if not already there
            if (!customers.any((c) => c['customerId'] == customerId)) {
              customers.insert(0, foundCustomer);
            }
          });
          print('✅ Specific customer fetched: ${foundCustomer['name']} (ID: $customerId)');
        } else {
          // Customer not found - this could happen if customer was deleted or shop changed
          print('⚠️ Customer ID $customerId not found in shop $shopId');
          if (mounted) {
            setState(() {
              selectedCustomerId = customerId; // Keep the ID so user can see it
              selectedCustomer = {
                'customerId': customerId,
                'name': 'Customer ID: $customerId (Not Found)',
              };
              dropdownCustomerController.text = 'Customer ID: $customerId (Not Found)';
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Customer ID $customerId not found. The customer may have been deleted or belongs to a different shop. Please select the correct customer.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching specific customer: $e');
      // Fallback to placeholder only if customerId is valid
      if (mounted && customerId != null && customerId != 0) {
        setState(() {
          selectedCustomerId = customerId;
          selectedCustomer = {
            'customerId': customerId,
            'name': 'Customer ID: $customerId (Error Loading)',
          };
          dropdownCustomerController.text = 'Customer ID: $customerId (Error Loading)';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customer ID $customerId. Please select the correct customer.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // Invalid customerId, clear selection
        if (mounted) {
          setState(() {
            selectedCustomerId = null;
            selectedCustomer = null;
            dropdownCustomerController.text = '';
          });
        }
      }
    }
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
      print('Error fetching all customers: $e');
      if (mounted) {
        setState(() {
          customers = [];
        });
      }
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

        if (mounted && initialFetch) {
          setState(() {
            dressTypes = newDressTypes;
          });
        }

        List<Map<String, dynamic>> allDressTypes = [
          ...existingDressTypes,
          ...newDressTypes
        ];
        // Only fetch more if we have a full page and it's not the initial fetch
        if (newDressTypes.length == pageSize && !initialFetch) {
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
            final controller = existingMeasurements[key] ?? 
                TextEditingController(text: '');
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

    print("🎨 Fetching patterns for dressTypeId=$dressTypeId, shopId=$id");

    try {
      // Step 1: Fetch ALL patterns from master list to use as fallback
      final allPatternsResponse = await ApiService().get("${Urls.getDressPattern}/$id", context);
      Map<int, Map<String, dynamic>> allPatternsMap = {};
      
      if (allPatternsResponse.data is Map<String, dynamic> &&
          allPatternsResponse.data.containsKey('data')) {
        final allPatterns = allPatternsResponse.data['data'] as List;
        for (var p in allPatterns) {
          final dressPatternId = p['dressPatternId'];
          if (dressPatternId != null) {
            // Check for DressPattern field first, then fallback to name
            final patternName = p['DressPattern'] ?? p['dressPattern'] ?? p['name'] ?? 'Pattern $dressPatternId';
            allPatternsMap[dressPatternId] = {
              '_id': p['_id']?.toString() ?? '',
              'dressPatternId': dressPatternId,
              'DressPattern': patternName?.toString()?.trim(),
              'name': patternName?.toString()?.trim() ?? 'Pattern $dressPatternId',
              'category': p['category']?.toString()?.trim() ?? 'Other',
              'selection': p['selection']?.toString()?.toLowerCase() ?? 'multiple',
            };
          }
        }
        print('🎨 Loaded ${allPatternsMap.length} patterns from master list');
      }

      // Step 2: Fetch dress-specific pattern relations
      final String requestUrl = "${Urls.orderDressTypeMea}/$id/$dressTypeId";
      print("🎨 Request URL for Patterns: $requestUrl");
      final response = await ApiService().get(requestUrl, context);
      print('🎨 Raw pattern response keys: ${response.data?.keys}');

      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedPatterns =
            response.data["DressTypeDressPattern"] ?? [];
        print('🎨 Fetched ${fetchedPatterns.length} dress-specific pattern relations');
        
        if (fetchedPatterns.isEmpty) {
          print('⚠️ No patterns found for dressTypeId=$dressTypeId');
          CustomSnackbar.showSnackbar(
            context,
            "No patterns available for this dress type",
            duration: Duration(seconds: 2),
          );
          return [];
        }
        
        final patterns = <Map<String, dynamic>>[];
        
        for (var pattern in fetchedPatterns) {
          print('🎨 Processing pattern relation: $pattern');
          
          // Get dressPatternId from the relation
          final dressPatternId = pattern['dressPatternId'] ?? 0;
          
          if (dressPatternId == 0) {
            print('⚠️ Warning: Missing dressPatternId, skipping: $pattern');
            continue;
          }
          
          // Try PatternDetails first, then fallback to master list
          final details = pattern['PatternDetails'] ?? pattern['patternDetails'] ?? {};
          final masterPattern = allPatternsMap[dressPatternId];
          
          // Use PatternDetails - check for DressPattern field first, then name
          String patternName = '';
          String patternCategory = '';
          String patternSelection = 'multiple';
          String patternId = '';
          
          // Check for DressPattern field first (database field name), then fallback to name
          final dressPatternValue = details['DressPattern'] ?? details['dressPattern'] ?? details['name'];
          
          if (dressPatternValue != null && 
              dressPatternValue.toString().trim().isNotEmpty &&
              dressPatternValue.toString().toLowerCase() != 'unnamed pattern') {
            // Use PatternDetails
            patternName = dressPatternValue.toString().trim();
            patternCategory = details['category']?.toString()?.trim() ?? '';
            patternSelection = details['selection']?.toString()?.toLowerCase() ?? 'multiple';
            patternId = details['_id']?.toString() ?? '';
            print('🎨 Using PatternDetails: name="$patternName" from DressPattern field');
          } else if (masterPattern != null) {
            // Use master pattern - also check for DressPattern field
            final masterName = masterPattern['DressPattern'] ?? masterPattern['dressPattern'] ?? masterPattern['name'];
            patternName = masterName?.toString()?.trim() ?? 'Pattern $dressPatternId';
            patternCategory = masterPattern['category'] ?? 'Other';
            patternSelection = masterPattern['selection'] ?? 'multiple';
            patternId = masterPattern['_id'] ?? '';
            print('🎨 Using master pattern: name="$patternName"');
          } else {
            // Last resort: use dressPatternId as name
            patternName = 'Pattern $dressPatternId';
            patternCategory = 'Other';
            patternSelection = 'multiple';
            patternId = dressPatternId.toString();
            print('🎨 Using fallback: name="$patternName"');
          }
          
          // Ensure we have a valid name
          if (patternName.isEmpty) {
            patternName = 'Pattern $dressPatternId';
          }
          
          // Ensure we have a valid category
          if (patternCategory.isEmpty) {
            patternCategory = 'Other';
          }
          
          // Ensure we have a valid ID
          if (patternId.isEmpty) {
            patternId = dressPatternId.toString();
          }
          
          print('🎨 ✅ Pattern: id=$patternId, dressPatternId=$dressPatternId, name="$patternName", category="$patternCategory", selection=$patternSelection');
          
          patterns.add({
            '_id': patternId,
            'dressPatternId': dressPatternId,
            'category': patternCategory,
            'name': patternName,
            'selection': patternSelection == 'single' ? 'single' : 'multiple',
          });
        }
            
        print('🎨 ✅ Processed ${patterns.length} patterns total');
        for (var p in patterns) {
          print('  - Pattern: name="${p['name']}", category="${p['category']}", selection=${p['selection']}');
        }
        
        if (patterns.isEmpty) {
          CustomSnackbar.showSnackbar(
            context,
            "No valid patterns found for this dress type",
            duration: Duration(seconds: 2),
          );
        }
        
        return patterns;
      }
      return [];
    } catch (e, stackTrace) {
      print("❌ Failed to load patterns: $e");
      print("❌ Stack trace: $stackTrace");
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
          // Get customerId from order, but validate it's not null or 0
          final orderCustomerId = order['customerId'];
          selectedCustomerId = (orderCustomerId != null && orderCustomerId != 0) ? orderCustomerId : null;
          // Normalize backend status to one of our known keys
          currentOrderStatus = _normalizeStatusKey(order['status']?.toString());
          
          // Only try to find/fetch customer if we have a valid customerId
          if (selectedCustomerId != null && selectedCustomerId != 0) {
            // Try to find the customer in the loaded customers list
            try {
              selectedCustomer = customers.firstWhere(
                (customer) => customer['customerId'] == selectedCustomerId,
                orElse: () => <String, dynamic>{},
              );
              
              if (selectedCustomer != null && selectedCustomer!.isNotEmpty) {
                dropdownCustomerController.text = selectedCustomer!['name'] ?? '';
                print('✅ Customer found: ${selectedCustomer!['name']} (ID: $selectedCustomerId)');
              } else {
                // Customer not found in the list, try to fetch it specifically
                print('⚠️ Customer ID $selectedCustomerId not found in customers list');
                print('Available customers: ${customers.map((c) => '${c['name']} (${c['customerId']})').join(', ')}');
                
                // Try to fetch the specific customer (async call)
                _fetchSpecificCustomer(selectedCustomerId!);
              }
            } catch (e) {
              print('❌ Error finding customer: $e');
              // Try to fetch the customer anyway
              _fetchSpecificCustomer(selectedCustomerId!);
            }
          } else {
            // Invalid customerId (null or 0) - show warning and clear customer selection
            print('⚠️ Invalid customerId in order: $orderCustomerId');
            selectedCustomerId = null;
            selectedCustomer = null;
            dropdownCustomerController.text = '';
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order has invalid customer ID. Please select a customer.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
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

          // Advance amount is now handled in payment section, not in order creation
          // advanceAmountController.text = order['advancereceived']?.toString() ?? '';

          orderItems = (order['items'] as List<dynamic>).map((item) {
            print("Selected Dress Type::::: ${item['dressTypeId']}");
            print("Available dress types: ${dressTypes.map((d) => '${d['name']} (${d['id']})').join(', ')}");
            
            final dressType = dressTypes.firstWhere(
              (dress) => dress['id'] == item['dressTypeId'],
              orElse: () => <String, dynamic>{},
            );

            String selectedDressTypeName = 'Unknown';
            Map<String, dynamic> selectedDressType = {};

            if (dressType.isNotEmpty) {
              selectedDressType = dressType;
              selectedDressTypeName = dressType['name'] ?? 'Unknown';
              print("✅ Dress type found: $selectedDressTypeName");
            } else {
              print("⚠️ No dress type found for dressTypeId: ${item['dressTypeId']}");
              // Try to fetch the specific dress type
              _fetchSpecificDressType(item['dressTypeId']).then((fetchedDressType) {
                if (fetchedDressType != null && mounted) {
                  setState(() {
                    // Update the order item with the fetched dress type
                    final itemIndex = orderItems.indexWhere((oi) => oi.selectedDressTypeId == item['dressTypeId']);
                    if (itemIndex != -1) {
                      orderItems[itemIndex].selectedDressType = fetchedDressType;
                      orderItems[itemIndex].dropdownDressController.text = fetchedDressType['name'] ?? 'Unknown';
                    }
                  });
                }
              });
            }

            print("Updated dropdownDressController with selected dress type: $selectedDressTypeName");

            // Extract IDs from measurement and pattern objects
            // Backend returns 'measurement' (lowercase) and 'Pattern' (uppercase)
            final measurementList = (item['measurement'] as List<dynamic>?) ?? [];
            // Check both 'Pattern' (uppercase - from backend) and 'pattern' (lowercase - fallback)
            final patternData = item['Pattern'] ?? item['pattern'];
            final patternList = (patternData as List<dynamic>?) ?? [];
            
            // Extract orderItemMeasurementId from the first measurement object
            int? extractedOrderItemMeasurementId;
            if (measurementList.isNotEmpty && measurementList[0] is Map<String, dynamic>) {
              final firstMeasurement = measurementList[0] as Map<String, dynamic>;
              extractedOrderItemMeasurementId = firstMeasurement['orderItemMeasurementId'] != null && firstMeasurement['orderItemMeasurementId'] > 0
                  ? firstMeasurement['orderItemMeasurementId'] as int?
                  : null;
            }
            // Fallback to item level if not found in measurement
            if (extractedOrderItemMeasurementId == null && item['orderItemMeasurementId'] != null && item['orderItemMeasurementId'] > 0) {
              extractedOrderItemMeasurementId = item['orderItemMeasurementId'] as int?;
            }
            
            // Extract orderItemPatternId from the pattern document wrapper (not from inner patterns array)
            // The backend returns Pattern as an array of pattern documents, each with orderItemPatternId at the document level
            int? extractedOrderItemPatternId;
            if (patternList.isNotEmpty && patternList[0] is Map<String, dynamic>) {
              final firstPatternDoc = patternList[0] as Map<String, dynamic>;
              // orderItemPatternId is at the pattern document level, not in the inner patterns array
              extractedOrderItemPatternId = firstPatternDoc['orderItemPatternId'] != null && firstPatternDoc['orderItemPatternId'] > 0
                  ? firstPatternDoc['orderItemPatternId'] as int?
                  : null;
              print('🔍 Extracted orderItemPatternId from pattern document: $extractedOrderItemPatternId');
            }
            // Fallback to item level if not found in pattern document
            if (extractedOrderItemPatternId == null && item['orderItemPatternId'] != null && item['orderItemPatternId'] > 0) {
              extractedOrderItemPatternId = item['orderItemPatternId'] as int?;
              print('🔍 Using orderItemPatternId from item level: $extractedOrderItemPatternId');
            }
            
            // If still null, this is a problem - log it
            if (extractedOrderItemPatternId == null && widget.orderId != null) {
              print('⚠️ WARNING: Could not extract orderItemPatternId for item ${item['orderItemId']}');
              print('   Pattern data: $patternData');
              print('   Pattern list length: ${patternList.length}');
              if (patternList.isNotEmpty) {
                print('   First pattern doc keys: ${(patternList[0] as Map).keys.toList()}');
              }
            }
            
            final orderItem = OrderItem(
              selectedDressType: selectedDressType.isNotEmpty ? selectedDressType : null,
              selectedDressTypeId: item['dressTypeId'],
              selectedOrderType: selectedOrderType,
              orderItemId: widget.orderId != null && item['orderItemId'] != null && item['orderItemId'] > 0 
                  ? item['orderItemId'] 
                  : null,
              orderItemMeasurementId: widget.orderId != null ? extractedOrderItemMeasurementId : null,
              orderItemPatternId: widget.orderId != null ? extractedOrderItemPatternId : null,
              measurements: measurementList
                      .expand<Map<String, dynamic>>((m) {
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
                      final value = entry.value?.toString() ?? '';
                      final controller = TextEditingController(text: value);
                      print(
                          'Created controller for ${entry.key} with value: ${controller.text}, hashCode: ${controller.hashCode}');
                      return {
                        'name': entry.key,
                        'dressTypeMeasurementId': m['orderItemMeasurementId'] ?? 0,
                        'value': controller,
                      };
                    });
                  }).toList(),
              selectedPatterns: patternList
                      .expand<Map<String, dynamic>>((pattern) {
                    return (pattern['patterns'] as List<dynamic>?)?.map((p) {
                          print(
                              'Pattern: category=${p['category']}, name=${p['name']}');
                          // Use the extracted orderItemPatternId or fallback to pattern's _id
                          // For existing orders, we MUST have orderItemPatternId
                          int? patternId;
                          if (widget.orderId != null) {
                            patternId = extractedOrderItemPatternId ?? 
                                       (pattern['orderItemPatternId'] != null && pattern['orderItemPatternId'] > 0 
                                         ? pattern['orderItemPatternId'] as int? 
                                         : null);
                            // Don't use _id as fallback - it's not the same as orderItemPatternId
                            if (patternId == null) {
                              print('⚠️ WARNING: Could not find orderItemPatternId for pattern, extractedOrderItemPatternId=$extractedOrderItemPatternId');
                            }
                          }
                          return {
                            'orderItemPatternId': patternId, // Use null instead of 0 - we'll check for null/0 separately
                            'category': p['category'] ?? 'Unknown',
                            'name': p['name'] is List
                                ? p['name']
                                : [p['name'].toString()],
                          };
                        }) ??
                        [];
                  }).toList(),
              specialInstructions: TextEditingController(
                  text: item['special_instructions'] ?? ''),
              deliveryDate: TextEditingController(
                text: item['delivery_date'] ?? item['deliveryDate'] ??
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
              ),
              originalCost:
                  TextEditingController(text: item['amount']?.toString() ?? ''),
              dropdownDressController:
                  TextEditingController(text: selectedDressTypeName),
            );
            
            // Load media for this order item if editing
            if (widget.orderId != null && item['orderItemId'] != null) {
              _loadOrderItemMedia(item['orderItemId'], orderItem);
            }

            // Add listener to order item cost controller for automatic total calculation
            orderItem.originalCost?.addListener(_updateTotalCost);
            
            return orderItem;
          }).toList();

          // Load additional costs from order data
          final additionalCostsData = (order['additionalCosts'] as List<dynamic>?) ?? [];
          additionalCostControllers = additionalCostsData.map((cost) {
                    final controller = <String, dynamic>{
                      'description': TextEditingController(
                          text: cost['additionalCostName']?.toString() ?? ''),
                      'amount': TextEditingController(
                          text: cost['additionalCost']?.toString() ?? ''),
                    };
                    // Add listener to amount controller
                    (controller['amount'] as TextEditingController)?.addListener(_updateTotalCost);
                    return controller;
                  }).toList();
          
          // If no additional costs exist, initialize with one empty controller
          if (additionalCostControllers.isEmpty) {
            additionalCostControllers = [
              {
                'description': TextEditingController(),
                'amount': TextEditingController(),
              }
            ];
          }

          // Add listeners to existing additional cost controllers
          for (var cost in additionalCostControllers) {
            cost['amount']?.addListener(_updateTotalCost);
          }

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

  String _normalizeStatusKey(String? raw) {
    final value = (raw ?? 'received').toString().trim().toLowerCase();
    // Map common backend variations to our UI keys
    if (value == 'in progress' || value == 'in-progress') return 'in_progress';
    if (value == 'received' || value == 'new') return 'received';
    if (value == 'completed' || value == 'complete') return 'completed';
    if (value == 'delivered' || value == 'delivery') return 'delivered';
    // Fallback to received if unknown to avoid -1 index
    return orderStatuses.any((s) => s['key'] == value) ? value : 'received';
  }

  String _toBackendStatusKey(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'in_progress' || v == 'in progress' || v == 'in-progress') {
      return 'in-progress';
    }
    if (v == 'received') return 'received';
    if (v == 'completed') return 'completed';
    if (v == 'delivered') return 'delivered';
    return 'received';
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
    
    // Calculate subtotal: items + additional costs
    final subtotal = totalOriginalCost + totalAdditionalCost;
    
    // Apply discount to subtotal
    final subtotalAfterDiscount = (subtotal - discountAmount).clamp(0.0, double.infinity);
    
    // Calculate GST on discounted subtotal (18%)
    final gstAmount = isGstChecked ? (subtotalAfterDiscount * 0.18) : 0.0;
    
    // Final total: discounted subtotal + courier + GST
    final total = subtotalAfterDiscount + courierAmount + gstAmount;
    
    totalCostController.text = total.toStringAsFixed(2);
    return total;
  }

  Future<void> _pickFromCamera(OrderItem item) async {
    try {
      print('📷 Picking image from camera for item');
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        print('📷 Image picked: ${pickedFile.name}, path: ${pickedFile.path}');
        setState(() {
          if (kIsWeb) {
            // On web, store XFile directly
            item.images.add(pickedFile);
            print('✅ Added XFile to item.images. Total images: ${item.images.length}');
          } else {
            // On mobile, convert to File
            item.images.add(File(pickedFile.path));
            print('✅ Added File to item.images. Total images: ${item.images.length}');
          }
        });
      } else {
        print('⚠️ No image picked from camera');
      }
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening camera: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery(OrderItem item) async {
    try {
      print('🖼️ Picking images from gallery for item');
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        print('🖼️ Picked ${pickedFiles.length} image(s) from gallery');
        setState(() {
          if (kIsWeb) {
            // On web, store XFile directly
            item.images.addAll(pickedFiles);
            print('✅ Added ${pickedFiles.length} XFile(s) to item.images. Total images: ${item.images.length}');
          } else {
            // On mobile, convert to File
            item.images.addAll(pickedFiles.map((file) => File(file.path)));
            print('✅ Added ${pickedFiles.length} File(s) to item.images. Total images: ${item.images.length}');
          }
        });
      } else {
        print('⚠️ No images picked from gallery');
      }
    } catch (e) {
      print('❌ Error picking images from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening gallery: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions(OrderItem item) {
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
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromCamera(item);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Select from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromGallery(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordAudio(OrderItem item) async {
    try {
      // If already recording for this item, stop and save
      if (_isRecording && _currentRecordingItem == item) {
        await _stopRecording(item);
        return;
      }

      // If recording for a different item, stop that first
      if (_isRecording && _currentRecordingItem != item) {
        await _stopRecording(_currentRecordingItem!);
      }

      // Check and request microphone permission
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            CustomSnackbar.showSnackbar(
              context,
              'Microphone permission is required to record audio',
              duration: Duration(seconds: 3),
            );
          }
          return;
        }
      }

      // Check if recorder is available
      if (await _audioRecorder.hasPermission() == false) {
        if (mounted) {
          CustomSnackbar.showSnackbar(
            context,
            'Microphone permission is required to record audio',
            duration: Duration(seconds: 3),
          );
        }
        return;
      }

      // Generate file path
      String filePath;
      if (kIsWeb) {
        // For web, we'll use a temporary path
        filePath = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        // For mobile, use app directory
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _currentRecordingPath = filePath;
        _currentRecordingItem = item;
        _recordingDuration = 0;
      });

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording && mounted) {
          setState(() {
            _recordingDuration++;
          });
        } else {
          timer.cancel();
        }
      });

      // Show recording dialog
      if (mounted) {
        _showRecordingDialog(item);
      }
    } catch (e) {
      print('❌ Error starting audio recording: $e');
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Failed to start recording: ${e.toString()}',
          duration: Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _stopRecording(OrderItem item) async {
    try {
      if (!_isRecording) return;

      // Stop the timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final path = await _audioRecorder.stop();
      
      if (path != null && path.isNotEmpty) {
        if (kIsWeb) {
          // On web (including mobile browsers), the record package returns a path
          // that can be used with File(path).readAsBytes()
          print('📱 Web/Mobile Browser: Processing audio recording from path: $path');
          
          try {
            // On web, File(path) should work with readAsBytes() for blob URLs
            // The record package handles the conversion internally
            final audioFile = File(path);
            
            // Try to read bytes to verify the file is accessible
            Uint8List bytes;
            try {
              bytes = await audioFile.readAsBytes();
              print('✅ Web: Successfully read ${bytes.length} bytes from audio file');
            } catch (readError) {
              // If direct read fails, it might be a blob URL - try HTTP fetch
              print('⚠️ Direct read failed, trying HTTP fetch: $readError');
              if (path.startsWith('blob:') || path.startsWith('http://') || path.startsWith('https://')) {
                final response = await http.get(Uri.parse(path));
                if (response.statusCode == 200) {
                  bytes = response.bodyBytes;
                  print('✅ Web: Successfully fetched ${bytes.length} bytes via HTTP');
                } else {
                  throw Exception('Failed to fetch audio: HTTP ${response.statusCode}');
                }
              } else {
                rethrow;
              }
            }
            
            final fileSize = bytes.length;
            final duration = _recordingDuration;
            
            setState(() {
              item.audioFiles.add(audioFile);
              _isRecording = false;
              _currentRecordingPath = null;
              _currentRecordingItem = null;
              _recordingDuration = 0;
            });

            if (mounted) {
              CustomSnackbar.showSnackbar(
                context,
                'Audio recorded successfully (${_formatDuration(duration)}, ${_formatFileSize(fileSize)})',
                duration: Duration(seconds: 3),
              );
            }
          } catch (e) {
            print('❌ Error processing web audio: $e');
            // Fallback: store the path anyway, upload will handle it
            final audioFile = File(path);
            final duration = _recordingDuration;
            
            setState(() {
              item.audioFiles.add(audioFile);
              _isRecording = false;
              _currentRecordingPath = null;
              _currentRecordingItem = null;
              _recordingDuration = 0;
            });

            if (mounted) {
              CustomSnackbar.showSnackbar(
                context,
                'Audio recorded successfully (${_formatDuration(duration)})',
                duration: Duration(seconds: 3),
              );
            }
          }
        } else {
          // On mobile (native), use File directly
          final audioFile = File(path);
          if (await audioFile.exists()) {
            final fileSize = await audioFile.length();
            final duration = _recordingDuration;
            
            setState(() {
              item.audioFiles.add(audioFile);
              _isRecording = false;
              _currentRecordingPath = null;
              _currentRecordingItem = null;
              _recordingDuration = 0;
            });

            if (mounted) {
              CustomSnackbar.showSnackbar(
                context,
                'Audio recorded successfully (${_formatDuration(duration)}, ${_formatFileSize(fileSize)})',
                duration: Duration(seconds: 3),
              );
            }
          } else {
            throw Exception('Recorded file does not exist');
          }
        }
      } else {
        throw Exception('No recording path returned');
      }
    } catch (e) {
      print('❌ Error stopping audio recording: $e');
      _recordingTimer?.cancel();
      _recordingTimer = null;
      setState(() {
        _isRecording = false;
        _currentRecordingPath = null;
        _currentRecordingItem = null;
        _recordingDuration = 0;
      });
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Failed to save recording: ${e.toString()}',
          duration: Duration(seconds: 3),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showRecordingDialog(OrderItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Update dialog state when recording state changes
            return StreamBuilder<bool>(
              stream: Stream.periodic(const Duration(milliseconds: 500), (_) => _isRecording),
              builder: (context, snapshot) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.mic, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Recording Audio'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          'Recording audio for this order item',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 24),
                      if (_isRecording) ...[
                        // Animated recording indicator
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 1000),
                          builder: (context, value, child) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1 + (value * 0.3)),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 2 + (value * 2),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.mic,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            if (_isRecording && mounted) {
                              setDialogState(() {});
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          _formatDuration(_recordingDuration),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Recording in progress...',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap "Stop & Save" when finished',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // Cancel recording
                        try {
                          if (_isRecording) {
                            _recordingTimer?.cancel();
                            _recordingTimer = null;
                            await _audioRecorder.stop();
                            // Delete the recorded file if it exists
                            if (_currentRecordingPath != null && !kIsWeb) {
                              try {
                                final file = File(_currentRecordingPath!);
                                if (await file.exists()) {
                                  await file.delete();
                                }
                              } catch (e) {
                                print('Error deleting canceled recording: $e');
                              }
                            }
                            setState(() {
                              _isRecording = false;
                              _currentRecordingPath = null;
                              _currentRecordingItem = null;
                              _recordingDuration = 0;
                            });
                          }
                        } catch (e) {
                          print('Error canceling recording: $e');
                        }
                      },
                      child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _stopRecording(item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Stop & Save'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Build media grid to display images and audio
  Widget _buildMediaGrid(OrderItem item) {
    List<Widget> mediaWidgets = [];

    // Add uploaded media (from server) - images
    for (var media in item.uploadedMedia) {
      if (media['mediaType'] == 'image') {
        mediaWidgets.add(_buildMediaThumbnail(
          media['mediaUrl'],
          isUploaded: true,
          onDelete: () async {
            // Delete from server (and S3 if applicable)
            await _deleteOrderItemMedia(media, item);
          },
        ));
      } else if (media['mediaType'] == 'audio') {
        mediaWidgets.add(_buildAudioThumbnail(
          media['mediaUrl'],
          isUploaded: true,
          onDelete: () async {
            // Delete from server (and S3 if applicable)
            await _deleteOrderItemMedia(media, item);
          },
        ));
      }
    }

    // Add local images (not yet uploaded)
    for (int i = 0; i < item.images.length; i++) {
      final image = item.images[i];
      mediaWidgets.add(_buildMediaThumbnail(
        image,
        isUploaded: false,
        onDelete: () {
          setState(() {
            item.images.removeAt(i);
          });
        },
      ));
    }

    // Add local audio files (not yet uploaded)
    for (int i = 0; i < item.audioFiles.length; i++) {
      final audioFile = item.audioFiles[i];
      mediaWidgets.add(_buildAudioThumbnail(
        audioFile,
        isUploaded: false,
        onDelete: () {
          setState(() {
            item.audioFiles.removeAt(i);
          });
        },
      ));
    }

    if (mediaWidgets.isEmpty) {
      return SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: mediaWidgets.length,
      itemBuilder: (context, index) => mediaWidgets[index],
    );
  }

  // Build individual media thumbnail
  Widget _buildMediaThumbnail(dynamic imageData, {required bool isUploaded, required VoidCallback onDelete}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUploaded
                ? Image.network(
                    // Check if URL is already a full URL (S3 URLs start with https://)
                    (imageData.toString().startsWith('http://') || imageData.toString().startsWith('https://'))
                        ? imageData.toString()
                        : '${Urls.baseUrl}$imageData',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  )
                : _buildLocalImage(imageData),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        if (!isUploaded)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pending',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  // Build audio thumbnail widget
  Widget _buildAudioThumbnail(dynamic audioData, {required bool isUploaded, required VoidCallback onDelete}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.blue.shade50,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.audiotrack,
                  size: 32,
                  color: Colors.blue.shade700,
                ),
                SizedBox(height: 4),
                Text(
                  'Audio',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        if (!isUploaded)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pending',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        // Play button overlay
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Play audio - for now just show a message
                if (isUploaded) {
                  // For uploaded audio, we'd need to play from URL
                  CustomSnackbar.showSnackbar(
                    context,
                    'Audio playback: ${audioData.toString()}',
                    duration: Duration(seconds: 2),
                  );
                } else {
                  // For local audio, we'd need to play from file
                  CustomSnackbar.showSnackbar(
                    context,
                    'Audio playback: ${audioData is File ? audioData.path : audioData.toString()}',
                    duration: Duration(seconds: 2),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white.withOpacity(0.8),
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build local image widget (handles both web and mobile)
  Widget _buildLocalImage(dynamic imageData) {
    if (kIsWeb) {
      // On web, imageData should be XFile
      if (imageData is XFile) {
        return _buildWebImage(imageData);
      } else {
        // Fallback: try to treat as XFile anyway
        try {
          return _buildWebImage(imageData as XFile);
        } catch (e) {
          return Container(
            color: Colors.grey.shade200,
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        }
      }
    } else {
      // On mobile, use Image.file
      if (imageData is File) {
        return Image.file(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      } else {
        return Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }
  }

  // Build image widget for web platform
  Widget _buildWebImage(XFile xFile) {
    return FutureBuilder<Uint8List>(
      future: xFile.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Container(
            color: Colors.grey.shade200,
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        } else {
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
      },
    );
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
    print('📥 Result is null: ${result == null}');
    
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
      
      // Refresh dress types for the newly selected customer
      fetchDressTypeData(
        pageNumber: 1,
        pageSize: pageSize,
        existingDressTypes: [],
      ).then((newDressTypes) {
        setState(() {
          dressTypes = newDressTypes;
        });
      });
    } else {
      print('❌ No customer data received or invalid format');
    }
  }

  // Load media for an order item when editing
  Future<void> _loadOrderItemMedia(int orderItemId, OrderItem item) async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null || widget.orderId == null) return;

    try {
      final String requestUrl = "${Urls.orderMedia}/$shopId/${widget.orderId}/$orderItemId";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data != null && response.data['data'] != null) {
        final mediaList = response.data['data'] as List<dynamic>;
        if (mounted) {
          setState(() {
            item.uploadedMedia = mediaList.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      print('Error loading media for orderItemId $orderItemId: $e');
      // Don't block order loading if media fetch fails
    }
  }

  // Delete media for an order item (from server and S3)
  Future<void> _deleteOrderItemMedia(Map<String, dynamic> media, OrderItem item) async {
    int? shopId = GlobalVariables.shopIdGet;
    final orderMediaId = media['orderMediaId'];
    
    if (shopId == null || orderMediaId == null) {
      print('❌ Cannot delete media: shopId=$shopId, orderMediaId=$orderMediaId');
      CustomSnackbar.showSnackbar(
        context,
        'Cannot delete media: Missing required information',
        duration: Duration(seconds: 2),
      );
      return;
    }

    try {
      print('🗑️ Deleting media: orderMediaId=$orderMediaId, shopId=$shopId');
      
      // Show loading indicator
      showLoader(context);
      
      // Call delete API
      final String deleteUrl = "${Urls.orderMedia}/$shopId/$orderMediaId";
      final response = await ApiService().delete(deleteUrl, context);
      
      hideLoader(context);
      
      if (response.data != null && response.data['success'] == true) {
        print('✅ Media deleted successfully from server and S3');
        
        // Remove from local state
        if (mounted) {
          setState(() {
            item.uploadedMedia.remove(media);
          });
        }
        
        CustomSnackbar.showSnackbar(
          context,
          'Image deleted successfully',
          duration: Duration(seconds: 2),
        );
      } else {
        throw Exception('Delete response indicates failure');
      }
    } catch (e) {
      hideLoader(context);
      print('❌ Error deleting media: $e');
      CustomSnackbar.showSnackbar(
        context,
        'Failed to delete image. Please try again.',
        duration: Duration(seconds: 2),
      );
    }
  }

  // Upload media files for an order item
  Future<void> _uploadOrderItemMedia(
    int shopId,
    int orderId,
    int orderItemId,
    OrderItem item,
  ) async {
    try {
      print('📤 Starting media upload for orderItemId: $orderItemId, images: ${item.images.length}');
      
      // Upload images
      for (var imageData in item.images) {
        try {
          print('📤 Processing image: ${imageData.runtimeType}');
          
          Response response;
          
          if (kIsWeb && imageData is XFile) {
            // On web, read bytes from XFile directly
            print('📤 Web: Reading bytes from XFile');
            final bytes = await imageData.readAsBytes();
            
            // Get filename - XFile.name might be empty, use path or generate
            String fileName = imageData.name;
            if (fileName.isEmpty) {
              // Try to extract from path
              final pathParts = imageData.path.split('/');
              if (pathParts.isNotEmpty) {
                fileName = pathParts.last;
                // Remove query parameters if present
                if (fileName.contains('?')) {
                  fileName = fileName.split('?').first;
                }
              }
            }
            // If still empty, generate a filename
            if (fileName.isEmpty || !fileName.contains('.')) {
              fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
            }
            
            print('📤 Web: Uploading ${bytes.length} bytes as $fileName');
            print('📤 Web: Upload URL: ${Urls.orderMedia}/upload');
            print('📤 Web: shopId=$shopId, orderId=$orderId, orderItemId=$orderItemId');
            
            // Create FormData manually for web
            final formData = FormData.fromMap({
              'shopId': shopId.toString(),
              'orderId': orderId.toString(),
              'orderItemId': orderItemId.toString(),
              'mediaType': 'image',
              'owner': GlobalVariables.userId?.toString() ?? '',
              'file': MultipartFile.fromBytes(
                bytes,
                filename: fileName,
                contentType: DioMediaType.parse('image/jpeg'), // Set mimetype explicitly
              ),
            });
            
            print('📤 Web: FormData created with ${formData.fields.length} fields');
            print('📤 Web: FormData files: ${formData.files.length}');
            if (formData.files.isNotEmpty) {
              print('📤 Web: File field name: ${formData.files.first.key}');
              print('📤 Web: File size: ${formData.files.first.value.length} bytes');
            }
            
            try {
              print('📤 Web: Calling postFormData...');
              response = await ApiService().postFormData(
                '${Urls.orderMedia}/upload',
                context,
                formData,
              );
              print('✅ Web: Upload response received: status=${response.statusCode}');
              print('✅ Web: Response data: ${response.data}');
            } catch (e, stackTrace) {
              print('❌ Web: Upload failed with error: $e');
              print('❌ Web: Error type: ${e.runtimeType}');
              print('❌ Web: Stack trace: $stackTrace');
              rethrow;
            }
          } else {
            // On mobile, use File directly
            final fileToUpload = imageData as File;
            print('📤 Mobile: Uploading file: ${fileToUpload.path}');
            
            response = await ApiService().uploadMediaFile(
              '${Urls.orderMedia}/upload',
              context,
              file: fileToUpload,
              fields: {
                'shopId': shopId.toString(),
                'orderId': orderId.toString(),
                'orderItemId': orderItemId.toString(),
                'mediaType': 'image',
                'owner': GlobalVariables.userId?.toString() ?? '',
              },
            );
          }

          if (response.data != null && response.data['data'] != null) {
            final uploadedMedia = response.data['data'] as Map<String, dynamic>;
            print('✅ Image uploaded successfully: ${uploadedMedia['mediaUrl']}');
            setState(() {
              item.uploadedMedia.add(uploadedMedia);
            });
          } else {
            print('⚠️ Upload response missing data: ${response.data}');
            print('⚠️ Full response: ${response.toString()}');
          }
        } catch (e, stackTrace) {
          print('❌ Error uploading image: $e');
          print('❌ Stack trace: $stackTrace');
          // Continue with other images even if one fails
        }
      }

      // Upload audio files
      print('📤 Starting audio upload for orderItemId: $orderItemId, audio files: ${item.audioFiles.length}');
      for (var audioFile in item.audioFiles) {
        try {
          print('📤 Processing audio file: ${audioFile.path}');
          
          Response response;
          
          if (kIsWeb) {
            // On web (including mobile browsers), handle audio file upload
            print('📤 Web/Mobile Browser: Processing audio file upload');
            print('📤 Audio file path: ${audioFile.path}');
            
            Uint8List bytes;
            try {
              // Try to read bytes directly (works if path is a blob URL that File can handle)
              bytes = await audioFile.readAsBytes();
              print('✅ Web: Successfully read ${bytes.length} bytes from audio file');
            } catch (e) {
              // If direct read fails, try fetching from URL (for blob URLs)
              print('⚠️ Direct read failed, trying HTTP fetch: $e');
              try {
                final httpResponse = await http.get(Uri.parse(audioFile.path));
                if (httpResponse.statusCode == 200) {
                  bytes = httpResponse.bodyBytes;
                  print('✅ Web: Successfully fetched ${bytes.length} bytes via HTTP');
                } else {
                  throw Exception('Failed to fetch audio: HTTP ${httpResponse.statusCode}');
                }
              } catch (httpError) {
                print('❌ Web: Both methods failed: $httpError');
                rethrow;
              }
            }
            
            // Get filename from path
            String fileName = audioFile.path.split('/').last;
            // Remove query parameters if present
            if (fileName.contains('?')) {
              fileName = fileName.split('?').first;
            }
            if (fileName.isEmpty || !fileName.contains('.')) {
              fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
            }
            
            // Determine MIME type from file extension
            String mimeType = 'audio/mp4'; // Default for m4a
            if (fileName.toLowerCase().endsWith('.mp3')) {
              mimeType = 'audio/mpeg';
            } else if (fileName.toLowerCase().endsWith('.wav')) {
              mimeType = 'audio/wav';
            } else if (fileName.toLowerCase().endsWith('.ogg')) {
              mimeType = 'audio/ogg';
            } else if (fileName.toLowerCase().endsWith('.aac')) {
              mimeType = 'audio/aac';
            } else if (fileName.toLowerCase().endsWith('.m4a')) {
              mimeType = 'audio/mp4'; // m4a uses mp4 MIME type
            }
            
            print('📤 Web: Uploading ${bytes.length} bytes as $fileName (MIME: $mimeType)');
            
            // Create FormData for audio
            final formData = FormData.fromMap({
              'shopId': shopId.toString(),
              'orderId': orderId.toString(),
              'orderItemId': orderItemId.toString(),
              'mediaType': 'audio',
              'owner': GlobalVariables.userId?.toString() ?? '',
              'file': MultipartFile.fromBytes(
                bytes,
                filename: fileName,
                contentType: DioMediaType.parse(mimeType),
              ),
            });
            
            try {
              print('📤 Web: Calling postFormData for audio...');
              response = await ApiService().postFormData(
                '${Urls.orderMedia}/upload',
                context,
                formData,
              );
              print('✅ Web: Audio upload response received: status=${response.statusCode}');
              print('✅ Web: Response data: ${response.data}');
            } catch (e, stackTrace) {
              print('❌ Web: Audio upload failed with error: $e');
              print('❌ Web: Error type: ${e.runtimeType}');
              print('❌ Web: Stack trace: $stackTrace');
              rethrow;
            }
          } else {
            // On mobile, use File directly
            print('📤 Mobile: Uploading audio file: ${audioFile.path}');
            
            response = await ApiService().uploadMediaFile(
              '${Urls.orderMedia}/upload',
              context,
              file: audioFile,
              fields: {
                'shopId': shopId.toString(),
                'orderId': orderId.toString(),
                'orderItemId': orderItemId.toString(),
                'mediaType': 'audio',
                'owner': GlobalVariables.userId?.toString() ?? '',
              },
            );
          }

          if (response.data != null && response.data['data'] != null) {
            final uploadedMedia = response.data['data'] as Map<String, dynamic>;
            print('✅ Audio uploaded successfully: ${uploadedMedia['mediaUrl']}');
            setState(() {
              item.uploadedMedia.add(uploadedMedia);
            });
          } else {
            print('⚠️ Audio upload response missing data: ${response.data}');
            print('⚠️ Full response: ${response.toString()}');
          }
        } catch (e, stackTrace) {
          print('❌ Error uploading audio: $e');
          print('❌ Stack trace: $stackTrace');
          // Continue with other audio files even if one fails
        }
      }

      // Clear local images after successful upload
      if (item.images.isNotEmpty) {
        print('✅ Cleared ${item.images.length} local image(s) after upload');
        setState(() {
          item.images.clear();
        });
      }

      // Clear local audio files after successful upload
      if (item.audioFiles.isNotEmpty) {
        print('✅ Cleared ${item.audioFiles.length} local audio file(s) after upload');
        setState(() {
          item.audioFiles.clear();
        });
      }
    } catch (e) {
      print('❌ Error uploading media: $e');
      // Don't block order save if media upload fails
    }
  }

  void onHandleSaveOrder() async {
  int? shopId = GlobalVariables.shopIdGet;
  int? branchId = GlobalVariables.branchId;
  int? userId = GlobalVariables.userId;

  // Validate required fields before proceeding
  if (selectedCustomerId == null) {
    CustomSnackbar.showSnackbar(
      context,
      'Please select a customer before saving the order',
      duration: Duration(seconds: 3),
    );
    return;
  }

  if (orderItems.isEmpty) {
    CustomSnackbar.showSnackbar(
      context,
      'Please add at least one item to the order',
      duration: Duration(seconds: 3),
    );
    return;
  }

  // Show loading indicator
  showLoader(context);

  List<Map<String, dynamic>> items = orderItems.map((item) {
    // Check if this is a new item (no orderItemId or orderItemId is 0/null)
    final isNewItem = widget.orderId == null || item.orderItemId == null || item.orderItemId == 0;
    
    // Extract orderItemMeasurementId from measurements (only for existing items, not new ones)
    int? orderItemMeasurementId = (!isNewItem && widget.orderId != null) ? item.orderItemMeasurementId : null;

    // Dynamically construct Measurement object based on available measurements
    Map<String, dynamic> measurementMap = {};
    
    // Include orderItemMeasurementId only for existing items (not new items)
    if (!isNewItem && orderItemMeasurementId != null && orderItemMeasurementId > 0) {
      measurementMap["orderItemMeasurementId"] = orderItemMeasurementId;
    }

    // Add only the measurement fields that exist in item.measurements
    if (item.measurements.isNotEmpty) {
      for (var m in item.measurements) {
        String key = m['name'].toString().toLowerCase().replaceAll(' ', '_');
        // Safely extract text value from TextEditingController
        String textValue = '';
        if (m['value'] is TextEditingController) {
          final controller = m['value'] as TextEditingController;
          textValue = controller.text.trim();
        }
        // Convert empty strings to null, valid numbers to double, invalid to null
        if (textValue.isEmpty) {
          measurementMap[key] = null;
        } else {
          final parsedValue = double.tryParse(textValue);
          measurementMap[key] = parsedValue; // null if parsing fails, which is acceptable
        }
      }
    }

    // Construct the Item map
    // isNewItem already defined above
    
    Map<String, dynamic> itemMap = {
      "dressTypeId": item.selectedDressTypeId,
      "Measurement": measurementMap,
      "Pattern": item.selectedPatterns.isNotEmpty
          ? item.selectedPatterns.asMap().entries.map((entry) {
              final index = entry.key;
              final pattern = entry.value;
              Map<String, dynamic> patternMap = {
                "category": pattern['category'] ?? 'Unknown',
                "name": pattern['name'] is List
                    ? pattern['name']
                    : [pattern['name'].toString()],
              };
              // Include orderItemPatternId only for existing items (not new items)
              // For existing items, the first pattern MUST have orderItemPatternId for backend validation
              if (!isNewItem) {
                // Get patternId from pattern object, or fallback to item's orderItemPatternId
                // Handle both int and dynamic types
                int? patternId;
                final patternIdValue = pattern['orderItemPatternId'];
                if (patternIdValue != null) {
                  if (patternIdValue is int && patternIdValue > 0) {
                    patternId = patternIdValue;
                  } else if (patternIdValue is num && patternIdValue.toInt() > 0) {
                    patternId = patternIdValue.toInt();
                  } else if (patternIdValue == 0) {
                    patternId = null; // 0 is not a valid ID
                  }
                }
                
                // If not found in pattern, use item's orderItemPatternId
                if ((patternId == null || patternId == 0) && item.orderItemPatternId != null && item.orderItemPatternId! > 0) {
                  patternId = item.orderItemPatternId;
                  print('🔍 Using item.orderItemPatternId=$patternId as fallback');
                }
                
                // Always set orderItemPatternId on the first pattern for existing items (required by backend)
                if (index == 0) {
                  if (patternId != null && patternId > 0) {
                    patternMap["orderItemPatternId"] = patternId;
                    print('✅ Setting orderItemPatternId=$patternId on first pattern for item ${item.orderItemId}');
                  } else {
                    // This is a critical error - backend will reject the request
                    print('❌ ERROR: Existing item ${item.orderItemId} missing orderItemPatternId for first pattern!');
                    print('   Pattern orderItemPatternId: ${pattern['orderItemPatternId']}');
                    print('   Item orderItemPatternId: ${item.orderItemPatternId}');
                    print('   Pattern keys: ${pattern.keys.toList()}');
                    // Still try to set it if item has it - backend will give a better error message
                    if (item.orderItemPatternId != null && item.orderItemPatternId! > 0) {
                      patternMap["orderItemPatternId"] = item.orderItemPatternId;
                      print('⚠️ Using item.orderItemPatternId as last resort: ${item.orderItemPatternId}');
                    }
                  }
                } else if (patternId != null && patternId > 0) {
                  // Optional: include ID for other patterns too if available
                  patternMap["orderItemPatternId"] = patternId;
                }
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
      "pictures": [], // Media is now handled separately via OrderMedia table
      "delivery_date": item.deliveryDate?.text?.trim().isNotEmpty == true
          ? item.deliveryDate!.text.trim()
          : DateFormat("yyyy-MM-dd").format(DateTime.now()),
      "amount": double.tryParse(item.originalCost?.text ?? "0") ?? 0.0,
      "status": _toBackendStatusKey(currentOrderStatus),
      "owner": userId.toString(),
    };

    // Add orderItemId only for existing items (not new items)
    if (!isNewItem && item.orderItemId != null && item.orderItemId! > 0) {
      itemMap["orderItemId"] = item.orderItemId;
    }

    return itemMap;
  }).toList();

  // Prepare additional costs for the new table
  List<Map<String, dynamic>> additionalCosts = additionalCostControllers
      .where((cost) => 
          (cost['description']?.text?.trim().isNotEmpty ?? false) &&
          (cost['amount']?.text?.trim().isNotEmpty ?? false))
      .map((cost) {
    return {
      "additionalCostName": cost['description']?.text ?? "",
      "additionalCost": double.tryParse(cost['amount']?.text ?? "0") ?? 0.0,
    };
  }).toList();

  int? selectedOrderTypeId;
  // Backend expects 1,2,3 per CommonEnumValues.StitchingTypes
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
      "customerId": selectedCustomerId!, // We've already validated this is not null
      "stitchingType": selectedOrderTypeId,
      "noOfMeasurementDresses": orderItems.length,
      "quantity": orderItems.length,
      "urgent": isUrgent,
      "status": _toBackendStatusKey(currentOrderStatus),
      "estimationCost": double.tryParse(totalCostController.text) ?? 0.0,
      "advancereceived": 0.0, // Advance amount is now handled in payment section
      "advanceReceivedDate": "", // No advance date when creating order
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
    "AdditionalCosts": additionalCosts,
  };

  print('Payload => $payload');

  try {
    var response;
    int? savedOrderId;
    
    if (widget.orderId != null) {
      // Update existing order
      final url = "${Urls.ordersSave}/$shopId/${widget.orderId}";
      response = await ApiService().put(url, data: payload, context);
      savedOrderId = widget.orderId;
    } else {
      // Create new order
      response = await ApiService().post(Urls.ordersSave, data: payload, context);
    }

    if (!mounted) {
      hideLoader(context);
      return;
    }

    print('🔍 Response received: ${response.data}');
    print('🔍 Response type: ${response.data.runtimeType}');
    
    if (response.data != null && response.data is Map<String, dynamic>) {
      final responseData = response.data as Map<String, dynamic>;
      final message = responseData['message'] ?? 'Order Saved Successfully';
      
      print('🔍 Response data keys: ${responseData.keys.toList()}');
      print('🔍 savedOrderId before: $savedOrderId');
      
      // Get the order ID (for new orders, it's in the response)
      if (savedOrderId == null) {
        savedOrderId = responseData['orderId'] ?? responseData['data']?['orderId'] ?? responseData['id'];
      }
      
      print('🔍 savedOrderId after: $savedOrderId');
      print('🔍 shopId: $shopId');
      print('🔍 orderItems.length: ${orderItems.length}');
      
      // Check each item for images
      for (int i = 0; i < orderItems.length; i++) {
        print('🔍 Item $i: orderItemId=${orderItems[i].orderItemId}, images=${orderItems[i].images.length}');
      }

      // Upload media files for each order item
      if (savedOrderId != null && shopId != null) {
        print('✅ CONDITIONS MET: Starting media upload process for orderId: $savedOrderId, shopId: $shopId');
        print('📤 Total order items: ${orderItems.length}');
        
        // Upload media for each item
        for (int i = 0; i < orderItems.length; i++) {
          final item = orderItems[i];
          print('📤 Processing item $i: has ${item.images.length} images, orderItemId: ${item.orderItemId}');
          
          // For updates, use the existing orderItemId directly
          // For new orders, try to get from response, otherwise use item's orderItemId
          int? orderItemId;
          
          if (widget.orderId != null) {
            // Updating existing order - use the orderItemId from the item
            // Only use if it's a valid ID (greater than 0)
            if (item.orderItemId != null && item.orderItemId! > 0) {
              orderItemId = item.orderItemId;
              print('✅ Update mode: Using orderItemId ${orderItemId} for item $i');
            } else {
              print('❌ Update mode: Invalid orderItemId ${item.orderItemId} for item $i');
              print('❌ Item details: selectedDressTypeId=${item.selectedDressTypeId}, images=${item.images.length}');
            }
          } else {
            // Creating new order - try to get from response
            List<dynamic> savedItems = [];
            if (responseData['data'] != null && responseData['data']['Item'] != null) {
              savedItems = responseData['data']['Item'] as List<dynamic>;
            } else if (responseData['Item'] != null) {
              savedItems = responseData['Item'] as List<dynamic>;
            } else if (responseData['data'] != null && responseData['data']['items'] != null) {
              savedItems = responseData['data']['items'] as List<dynamic>;
            }
            
            print('📤 Create mode: Found ${savedItems.length} saved items in response');
            
            if (i < savedItems.length) {
              final savedItemId = savedItems[i]['orderItemId'];
              if (savedItemId != null && savedItemId > 0) {
                orderItemId = savedItemId;
                print('✅ Create mode: Got orderItemId ${orderItemId} from response for item $i');
              } else {
                print('❌ Create mode: Saved item $i has invalid orderItemId: $savedItemId');
              }
            } else if (item.orderItemId != null && item.orderItemId! > 0) {
              orderItemId = item.orderItemId;
              print('✅ Create mode: Using item.orderItemId ${orderItemId} for item $i');
            } else {
              print('❌ Create mode: No valid orderItemId found for item $i');
            }
          }
          
          // Upload media if we have a valid orderItemId and media (images or audio) to upload
          final hasImages = item.images.isNotEmpty;
          final hasAudio = item.audioFiles.isNotEmpty;
          if (orderItemId != null && orderItemId > 0 && (hasImages || hasAudio)) {
            print('🚀 UPLOADING media for orderItemId: $orderItemId, orderId: $savedOrderId, shopId: $shopId');
            print('   - Images: ${item.images.length}');
            print('   - Audio files: ${item.audioFiles.length}');
            try {
              await _uploadOrderItemMedia(shopId, savedOrderId, orderItemId, item);
              print('✅ Upload completed for item $i');
            } catch (e, stackTrace) {
              print('❌ Upload failed for item $i: $e');
              print('❌ Stack trace: $stackTrace');
              // Don't throw - continue with other items
            }
          } else {
            if (hasImages || hasAudio) {
              print('❌ SKIPPING upload: orderItemId is invalid (${orderItemId}) for item $i');
              print('   - Has ${item.images.length} images, ${item.audioFiles.length} audio files');
            } else {
              print('ℹ️ No media to upload for item $i');
            }
          }
        }
        print('📤 Media upload process completed');
      } else {
        print('❌ Cannot upload media: savedOrderId=$savedOrderId, shopId=$shopId');
      }

      hideLoader(context);

      CustomSnackbar.showSnackbar(
        context,
        message,
        duration: Duration(seconds: 2),
      );
      
      if(widget.orderId == null){
        // For new orders, navigate to order detail page
        if (savedOrderId != null) {
          Navigator.pushReplacementNamed(
            context, 
            AppRoutes.orderDetailsScreen,
            arguments: savedOrderId,
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        // For updated orders, navigate to order detail page
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.orderDetailsScreen,
          arguments: widget.orderId,
        );
      }
    } else {
      hideLoader(context);
      CustomSnackbar.showSnackbar(
        context,
        'Failed to save order',
        duration: Duration(seconds: 2),
      );
    }
  } catch (e) {
    hideLoader(context);
    print('Error: $e');
    
    // Parse error message for better user feedback
    String errorMessage = 'Failed to save order';
    if (e.toString().contains('customerId')) {
      errorMessage = 'Customer selection is required. Please select a customer.';
    } else if (e.toString().contains('400')) {
      errorMessage = 'Invalid data provided. Please check all fields and try again.';
    } else if (e.toString().contains('500')) {
      errorMessage = 'Server error. Please try again later.';
    } else if (e.toString().contains('network') || e.toString().contains('connection')) {
      errorMessage = 'Network error. Please check your connection and try again.';
    }
    
    CustomSnackbar.showSnackbar(
      context,
      errorMessage,
      duration: Duration(seconds: 3),
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
    // Show loading while checking permissions
    if (!_permissionChecked) {
      return Scaffold(
        backgroundColor: ColorPalatte.white,
        appBar: Commonheader(
          title: widget.orderId != null
              ? Textstring().updateOrder
              : Textstring().createorder,
          showBackArrow: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Block access if no permission
    if (!_hasAccess) {
      return Scaffold(
        backgroundColor: ColorPalatte.white,
        appBar: Commonheader(
          title: 'Access Denied',
          showBackArrow: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage ?? 'You do not have permission to ${widget.orderId != null ? 'edit' : 'create'} orders',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
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
                        child: Row(
                          children: [
                            Text('Customer', style: Createorderstyle.selecteCustomer),
                            if (selectedCustomerId == null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(Required)',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
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
                  // Order Status Stepper (only show in edit mode)
                  if (widget.orderId != null) ...[
                    const SizedBox(height: 20),
                    _buildOrderStatusStepper(),
                  ],
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
                                // Collapse all other items
                                for (var i = 0; i < orderItems.length; i++) {
                                  if (i != index) {
                                    orderItems[i].isExpanded = false;
                                  }
                                }
                                // Toggle the current item
                                item.isExpanded = !item.isExpanded;
                              });
                              
                              // Scroll to the clicked item if it's being expanded
                              if (item.isExpanded) {
                                Future.delayed(Duration(milliseconds: 100), () {
                                  if (mounted && _scrollController.hasClients) {
                                    // Calculate approximate position of the item
                                    final itemHeight = 200.0; // Approximate height of expanded item
                                    final targetPosition = (index * itemHeight).clamp(
                                      0.0, 
                                      _scrollController.position.maxScrollExtent,
                                    );
                                    _scrollController.animateTo(
                                      targetPosition,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }
                            },
                            child: Column(
                              children: [
                                // Highlighted header section
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: ColorPalatte.primary.withOpacity(0.1),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: ColorPalatte.primary.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: ColorPalatte.primary,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        "Item ${index + 1}",
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.white),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    if (item.selectedDressType != null)
                                                      Text(
                                                        item.selectedDressType!['name'] ?? 'Unknown Dress',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[700],
                                                            fontWeight: FontWeight.w600),
                                                      )
                                                    else
                                                      Text(
                                                        'Select Dress Type',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[500],
                                                            fontStyle: FontStyle.italic),
                                                      ),
                                                  ],
                                                ),
                                                IconButton(
                                                  onPressed: () => _showDeleteConfirmation(index),
                                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                                  tooltip: 'Remove Item',
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(),
                                                ),
                                              ],
                                            ),
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
                                // Expanded content section
                                if (item.isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 12),
                                    child: Column(
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
                                              item.dropdownDressController.text =
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
                                                child: _buildButton(
                                                    _isRecording && _currentRecordingItem == item
                                                        ? "⏹ Stop Recording"
                                                        : "🎙 Record Audio",
                                                    onPressed: () => _recordAudio(item),
                                                    color: _isRecording && _currentRecordingItem == item
                                                        ? Colors.red
                                                        : null)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: _buildButton("📷 Take Picture",
                                                    onPressed: () => _showImagePickerOptions(item))),
                                          ],
                                        ),
                                        // Display uploaded and local media (images and audio)
                                        if (item.images.isNotEmpty || item.audioFiles.isNotEmpty || item.uploadedMedia.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Icon(Icons.photo_library, size: 18, color: ColorPalatte.primary),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Pictures',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: ColorPalatte.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${(item.images.length + item.uploadedMedia.length)} ${(item.images.length + item.uploadedMedia.length) == 1 ? 'picture' : 'pictures'})',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildMediaGrid(item),
                                        ],
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomDatePicker(
                                                label: Textstring().deliveryDate,
                                                controller: item.deliveryDate!,
                                                allowFutureOnly: true,
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
                                        // Only show cost field if user has viewPrice permission
                                        if (GlobalVariables.hasPermission('viewPrice')) ...[
                                          Text('Cost'),
                                          SizedBox(height: 5),
                                          _buildTextField(
                                            "Enter cost",
                                            keyboardType: TextInputType.number,
                                            controller: item.originalCost,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  SizedBox(height: 15),
                  _buildAddItemButton(),
                  // Only show additional cost section if user has viewPrice permission
                  if (GlobalVariables.hasPermission('viewPrice')) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Additional Cost",
                            style: Createorderstyle.selecteCustomer),
                        _buildIconButtonCost(Icons.add_circle, () {
                          setState(() {
                            final newCost = {
                              'description': TextEditingController(),
                              'amount': TextEditingController(),
                            };
                            // Add listener to the new cost controller
                            newCost['amount']?.addListener(_updateTotalCost);
                            additionalCostControllers.add(newCost);
                          });
                        }),
                      ],
                    ),
                    _buildAdditionalCostFields(),
                  ],
                  const SizedBox(height: 12),
                  // Only show courier field if user has viewPrice permission
                  if (GlobalVariables.hasPermission('viewPrice'))
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
                      // Only show GST field if user has viewPrice permission
                      if (GlobalVariables.hasPermission('viewPrice')) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: isGstChecked,
                              activeColor: Colors.brown,
                              onChanged: (value) {
                                setState(() {
                                  isGstChecked = value!;
                                  // Recalculate total when GST checkbox changes
                                  _updateTotalCost();
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
                  // Only show discount, total cost, and advance if user has viewPrice permission
                  if (GlobalVariables.hasPermission('viewPrice')) ...[
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
                  ],
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: selectedCustomerId == null ? Colors.orange : Colors.grey,
              width: selectedCustomerId == null ? 2 : 1,
            ),
          ),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        );
      },
    );
  }

  Widget _buildOrderStatusStepper() {
    final currentIndex = orderStatuses.indexWhere((status) => status['key'] == currentOrderStatus);
    // Ensure currentIndex is valid, default to 0 if not found
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorPalatte.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Status Path/Stepper
              Row(
                children: orderStatuses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final status = entry.value;
                  final isActive = index <= safeIndex;
                  final isCurrent = index == safeIndex;
                  
                  return Expanded(
                    child: Row(
                      children: [
                        // Status Circle
                        GestureDetector(
                          onTap: () => _updateOrderStatus(status['key']),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive ? status['color'] : Colors.grey.shade300,
                              shape: BoxShape.circle,
                              border: isCurrent ? Border.all(color: status['color'], width: 3) : null,
                            ),
                            child: Icon(
                              status['icon'],
                              color: isActive ? Colors.white : Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                        // Connector Line (except for last item)
                        if (index < orderStatuses.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isActive ? status['color'] : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Current Status Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: orderStatuses[safeIndex]['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: orderStatuses[safeIndex]['color'].withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      orderStatuses[safeIndex]['icon'],
                      color: orderStatuses[safeIndex]['color'],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderStatuses[safeIndex]['label'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: orderStatuses[safeIndex]['color'],
                            ),
                          ),
                          Text(
                            orderStatuses[safeIndex]['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Quick Status Update Buttons - only show if user has manageOrderStatus permission
              if (GlobalVariables.hasPermission('manageOrderStatus'))
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: orderStatuses.map((status) {
                    final isCurrent = status['key'] == currentOrderStatus;
                    return ElevatedButton(
                      onPressed: isCurrent ? null : () => _updateOrderStatus(status['key']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent ? status['color'] : Colors.white,
                        foregroundColor: isCurrent ? Colors.white : status['color'],
                        side: BorderSide(color: status['color']),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        status['label'],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateOrderStatus(String newStatus) async {
    setState(() {
      currentOrderStatus = newStatus;
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order status updated to: ${orderStatuses.firstWhere((s) => s['key'] == newStatus)['label']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-save status change to backend if editing existing order
    if (widget.orderId != null) {
      await _saveStatusToBackend(newStatus);
    }
  }

  Future<void> _saveStatusToBackend(String status) async {
    try {
      final int? shopId = GlobalVariables.shopIdGet;
      final int? branchId = GlobalVariables.branchId;
      final int? userId = GlobalVariables.userId;
      if (shopId == null || widget.orderId == null || selectedCustomerId == null) {
        return;
      }

      // Build Items payload with required IDs for update validation
      final List<Map<String, dynamic>> items = orderItems.map((item) {
        // Measurement map must include orderItemMeasurementId for update
        final Map<String, dynamic> measurementMap = {
          if (item.orderItemMeasurementId != null)
            "orderItemMeasurementId": item.orderItemMeasurementId,
        };
        for (final m in item.measurements) {
          final String key = m['name'].toString().toLowerCase().replaceAll(' ', '_');
          String textValue = '';
          if (m['value'] is TextEditingController) {
            textValue = (m['value'] as TextEditingController).text.trim();
          }
          // Convert empty strings to null, valid numbers to double, invalid to null
          if (textValue.isEmpty) {
            measurementMap[key] = null;
          } else {
            final parsedValue = double.tryParse(textValue);
            measurementMap[key] = parsedValue; // null if parsing fails, which is acceptable
          }
        }

        // Pattern list must include orderItemPatternId for update
        final List<Map<String, dynamic>> patternList = (item.selectedPatterns.isNotEmpty
                ? item.selectedPatterns
                : <Map<String, dynamic>>[
                    {"category": "Unknown", "name": ["None"]}
                  ])
            .map((pattern) {
          final Map<String, dynamic> patternMap = {
            "category": pattern['category'] ?? 'Unknown',
            "name": pattern['name'] is List ? pattern['name'] : [pattern['name'].toString()],
          };
          if (item.orderItemPatternId != null) {
            patternMap["orderItemPatternId"] = item.orderItemPatternId;
          }
          return patternMap;
        }).toList();

        return {
          // IDs are required by update service/validation
          if (item.orderItemId != null) "orderItemId": item.orderItemId,
          "dressTypeId": item.selectedDressTypeId,
          "Measurement": measurementMap,
          "Pattern": patternList,
          "special_instructions": item.specialInstructions?.text ?? "",
          "recording": "",
          "videoLink": "",
          "pictures": [], // Media is now handled separately via OrderMedia table
          "delivery_date": item.deliveryDate?.text?.trim().isNotEmpty == true
              ? item.deliveryDate!.text.trim()
              : DateFormat("yyyy-MM-dd").format(DateTime.now()),
          "amount": double.tryParse(item.originalCost?.text ?? "0") ?? 0.0,
          "status": _toBackendStatusKey(status),
          "owner": userId?.toString() ?? '',
        };
      }).toList();

      // Map order type text to backend integer
      int? selectedOrderTypeId;
      // Backend expects 1,2,3 per CommonEnumValues.StitchingTypes
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
          "status": _toBackendStatusKey(status),
          "estimationCost": double.tryParse(totalCostController.text) ?? 0.0,
          "advancereceived": 0.0, // Advance amount is now handled in payment section
          "advanceReceivedDate": "", // No advance date when updating order status
          "gst": isGstChecked,
          "gst_amount": isGstChecked ? (double.tryParse(gstController.text) ?? 0.0) : 0.0,
          "Courier": isCourierChecked,
          "courierCharge": double.tryParse(courierController.text) ?? 0.0,
          "discount": double.tryParse(discountController.text) ?? 0.0,
          "owner": userId?.toString() ?? '',
        },
        "Item": items,
      };

      final url = "${Urls.ordersSave}/$shopId/${widget.orderId}";
      final response = await ApiService().put(url, data: payload, context);

      if (response.data != null && response.data is Map<String, dynamic>) {
        print('✅ Status updated successfully in backend: ${_toBackendStatusKey(status)}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status saved: ${orderStatuses.firstWhere((s) => s['key'] == status)['label']}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        print('⚠️ Failed to update status in backend');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save status'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating status in backend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving status: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddItemOptions(),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalatte.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Add Another Item"),
      ),
    );
  }

  void _showAddItemOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add New Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorPalatte.primary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: ColorPalatte.primary),
              title: const Text('Create New Item'),
              subtitle: const Text('Start with a blank item'),
              onTap: () {
                Navigator.pop(context);
                _addNewItem();
              },
            ),
            // Show "Copy from Previous Item" option if there's at least one item with data
            if (orderItems.any((item) => 
              item.selectedDressTypeId != null && 
              item.selectedDressType != null &&
              item.measurements.isNotEmpty
            )) ...[
              const Divider(),
              ListTile(
                leading: Icon(Icons.copy, color: ColorPalatte.primary),
                title: const Text('Copy from Previous Item'),
                subtitle: const Text('Copy measurements and patterns from existing item'),
                onTap: () {
                  Navigator.pop(context);
                  _showCopyFromDialog();
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addNewItem() {
    setState(() {
      // Collapse all existing items
      for (var item in orderItems) {
        item.isExpanded = false;
      }
      // Add new item and expand it
      final newItem = OrderItem(isExpanded: true);
      // Add listener to the new item's cost controller
      newItem.originalCost?.addListener(_updateTotalCost);
      orderItems.add(newItem);
    });
    
    // Scroll to the new item after a short delay to ensure it's rendered
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCopyFromDialog() {
    // Filter out the last item (which is likely empty) and items without dress type
    final copyableItems = orderItems.where((item) => 
      item.selectedDressTypeId != null && 
      item.selectedDressType != null &&
      item.measurements.isNotEmpty
    ).toList();

    if (copyableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items available to copy from. Please add measurements to an item first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Copy from Previous Item',
          style: TextStyle(color: ColorPalatte.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: copyableItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final dressTypeName = item.selectedDressType?['name'] ?? 'Unknown Dress';
            final measurementCount = item.measurements.length;
            final patternCount = item.selectedPatterns.length;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: ColorPalatte.primary.withOpacity(0.1),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: ColorPalatte.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(dressTypeName),
              subtitle: Text('$measurementCount measurements, $patternCount patterns'),
              onTap: () {
                Navigator.pop(context);
                _copyFromItem(item);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _copyFromItem(OrderItem sourceItem) {
    setState(() {
      // Collapse all existing items
      for (var item in orderItems) {
        item.isExpanded = false;
      }
      // Create new item by copying from source
      final newItem = OrderItem().copyFrom(sourceItem);
      // Add listener to the new item's cost controller
      newItem.originalCost?.addListener(_updateTotalCost);
      orderItems.add(newItem);
    });
    
    // Scroll to the new item after a short delay to ensure it's rendered
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied measurements and patterns from ${sourceItem.selectedDressType?['name'] ?? 'previous item'}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    final item = orderItems[index];
    final dressTypeName = item.selectedDressType?['name'] ?? 'Item ${index + 1}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Remove Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove this item?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dressTypeName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorPalatte.primary,
                    ),
                  ),
                  if (item.measurements.isNotEmpty)
                    Text(
                      '${item.measurements.length} measurements',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  if (item.selectedPatterns.isNotEmpty)
                    Text(
                      '${item.selectedPatterns.length} patterns',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      orderItems.removeAt(index);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item ${index + 1} removed successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Note: Undo functionality would require storing the removed item
            // For now, just show a message that undo is not available
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Undo not available. Please add the item again if needed.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(String text, {VoidCallback? onPressed, Color? color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? ColorPalatte.primary,
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
              // Only show amount field if user has viewPrice permission
              if (GlobalVariables.hasPermission('viewPrice'))
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
  List<dynamic> images = []; // Images for this order item (File for mobile, XFile for web)
  List<File> audioFiles = []; // Audio files for this order item
  List<Map<String, dynamic>> uploadedMedia = []; // Media already uploaded to server

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
    List<dynamic>? images,
    List<File>? audioFiles,
    List<Map<String, dynamic>>? uploadedMedia,
  })  : originalCost = originalCost ?? TextEditingController(),
        specialInstructions = specialInstructions ?? TextEditingController(),
        dropdownDressController = dropdownDressController ??
            TextEditingController(text: "Select Dress Type"),
        deliveryDate = deliveryDate ??
            TextEditingController(
                text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 1)))),
        images = images ?? [],
        audioFiles = audioFiles ?? [],
        uploadedMedia = uploadedMedia ?? [];

  // Method to create a copy of this OrderItem
  OrderItem copyFrom(OrderItem source) {
    // Copy measurements with new controllers
    List<Map<String, dynamic>> copiedMeasurements = source.measurements.map((measurement) {
      // Safely extract text value to avoid TextSelection.invalid issues
      String textValue = '';
      if (measurement['value'] is TextEditingController) {
        final controller = measurement['value'] as TextEditingController;
        textValue = controller.text;
      }
      
      return {
        'name': measurement['name'],
        'dressTypeMeasurementId': measurement['dressTypeMeasurementId'],
        'value': TextEditingController(text: textValue),
      };
    }).toList();

    // Copy patterns (no need for new controllers as they're just data)
    List<Map<String, dynamic>> copiedPatterns = List.from(source.selectedPatterns);

    // Copy other properties with new controllers
    return OrderItem(
      selectedDressType: source.selectedDressType,
      selectedDressTypeId: source.selectedDressTypeId,
      selectedOrderType: source.selectedOrderType,
      showPatternGrid: source.showPatternGrid,
      measurements: copiedMeasurements,
      selectedPatterns: copiedPatterns,
      isExpanded: true, // New item should be expanded
      deliveryDate: TextEditingController(text: source.deliveryDate?.text ?? ''),
      originalCost: TextEditingController(text: source.originalCost?.text ?? ''),
      specialInstructions: TextEditingController(text: source.specialInstructions?.text ?? ''),
      dropdownDressController: TextEditingController(text: source.dropdownDressController.text),
      images: kIsWeb 
          ? List.from(source.images) // On web, keep XFile objects
          : List.from(source.images.map((img) => img is File ? File((img as File).path) : img)), // On mobile, ensure File objects
      audioFiles: List.from(source.audioFiles),
      uploadedMedia: List.from(source.uploadedMedia),
    );
  }
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

  void _filterCustomers() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredCustomers = List.from(_allCustomers);
      });
      return;
    }

    // Use the new search endpoint for real-time search
    await _searchCustomersFromAPI(_searchQuery);
  }

    Future<void> _searchCustomersFromAPI(String searchKeyword) async {
      if (_isLoading || !mounted) return;

      setState(() {
        _isLoading = true;
      });

      int? shopId = GlobalVariables.shopIdGet;
      if (shopId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      try {
        final String requestUrl = "${Urls.customer}/$shopId/search?searchKeyword=$searchKeyword";
        final response = await ApiService().get(requestUrl, context);

        if (mounted) {
          if (response.data is Map<String, dynamic> && response.data['success'] == true) {
            List<dynamic> customerData = response.data['data'];
            List<Map<String, dynamic>> searchResults = customerData.cast<Map<String, dynamic>>();

            setState(() {
              _filteredCustomers = searchResults;
              _isLoading = false;
            });
          } else {
            setState(() {
              _filteredCustomers = [];
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Error searching customers: $e');
        if (mounted) {
          setState(() {
            _filteredCustomers = [];
            _isLoading = false;
          });
        }
      }
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
                
      // Debounce the search to avoid too many API calls (reduced from 500ms to 300ms)
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _filterCustomers();
      });
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

    // Include searchKeyword in the request URL if provided
    String requestUrl = "${Urls.addDress}/$id?pageNumber=$_pageNumber&pageSize=$_pageSize";
    if (_searchQuery.isNotEmpty) {
      requestUrl += "&searchKeyword=${Uri.encodeComponent(_searchQuery)}";
    }

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
            // If searching, replace the list; otherwise append for pagination
            if (_searchQuery.isNotEmpty || initialFetch) {
              _dressTypes = newDressTypes;
            } else {
              _dressTypes = [..._dressTypes, ...newDressTypes];
            }
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
    // No need for client-side filtering - backend handles search
    final filteredItems = _dressTypes;

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
                  // Reset pagination when search changes
                  _pageNumber = 1;
                  _dressTypes = [];
                  _hasMoreData = true;
                });
                // Debounce search to avoid too many API calls
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _fetchDressTypes(initialFetch: true);
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredItems.isEmpty && !_isLoading
                  ? Center(child: Text('No dress types found'))
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
