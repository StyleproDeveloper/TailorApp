import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tailorapp/Routes/App_route.dart';
import '../../../../Core/Constants/ColorPalatte.dart';
import '../../../../Core/Services/Services.dart';
import '../../../../Core/Services/Urls.dart';
import '../../../../Core/Widgets/CommonHeader.dart';
import '../../../../Core/Widgets/CustomLoader.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';
import '../../../../GlobalVariables.dart';

class Customerscreen extends StatefulWidget {
  const Customerscreen({super.key});

  @override
  State<Customerscreen> createState() => _CustomerscreenState();
}

class _CustomerscreenState extends State<Customerscreen> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> allCustomers = [];
  final ScrollController _scrollController = ScrollController();
  int pageNumber = 1;
  final int pageSize = 10;
  bool hasMoreData = true;
  bool isLoading = false;
  TextEditingController searchKeywordController = TextEditingController();
  Timer? _debounce;
  bool _isInitialFetch = true;
  String selectedFilter = 'All'; // All, Newly Created, Active Customer

  @override
  void initState() {
    super.initState();
    _fetchcustomerData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchcustomerData();
      _scrollController.addListener(_scrollListener);
      searchKeywordController.addListener(_onSearchChanged);
    });
  }

  void _scrollListener() {
    if (!isLoading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100) {
      _fetchcustomerData();
    }
  }

  void _onSearchChanged() {
    if (searchKeywordController.text.isNotEmpty) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          customers.clear();
          pageNumber = 1;
          hasMoreData = true;
        });
        _fetchcustomerData();
      });
    } else if (searchKeywordController.text.isEmpty) {
      setState(() {
        customers.clear();
        pageNumber = 1;
        hasMoreData = true;
      });
      _fetchcustomerData();
    }
  }

  void _resetAndFetch() {
    setState(() {
      customers.clear();
      allCustomers.clear();
      pageNumber = 1;
      hasMoreData = true;
    });
    _fetchcustomerData();
  }

  void _sortCustomersAlphabetically() {
    customers.sort((a, b) {
      String nameA = (a['name'] ?? '').toString().toLowerCase();
      String nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });
    allCustomers.sort((a, b) {
      String nameA = (a['name'] ?? '').toString().toLowerCase();
      String nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    
    switch (filter) {
      case 'Newly Created':
        _fetchNewlyCreatedCustomers();
        break;
      case 'Active Customer':
        _fetchActiveCustomers();
        break;
      default: // 'All'
        setState(() {
          customers = List.from(allCustomers);
        });
        _sortCustomersAlphabetically();
        setState(() {});
        break;
    }
  }

  void _fetchNewlyCreatedCustomers() async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Fetch with larger page size to get recent customers, then limit to 10
      final String requestUrl = "${Urls.customer}/$id?pageNumber=1&pageSize=50&searchKeyword=";
      final response = await ApiService().get(requestUrl, context);

      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedCustomers = response.data['data'];
        List<Map<String, dynamic>> customerList = List<Map<String, dynamic>>.from(fetchedCustomers);
        
        // Sort by creation date (most recent first)
        customerList.sort((a, b) {
          DateTime dateA = DateTime.parse(a['createdAt'] ?? DateTime.now().toString());
          DateTime dateB = DateTime.parse(b['createdAt'] ?? DateTime.now().toString());
          return dateB.compareTo(dateA);
        });

        setState(() {
          customers = customerList.take(10).toList(); // Take only the 10 most recent
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _fetchActiveCustomers() async {
    int? id = GlobalVariables.shopIdGet;
    if (id == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // First fetch all customers
      final String customerUrl = "${Urls.customer}/$id?pageNumber=1&pageSize=100&searchKeyword=";
      final customerResponse = await ApiService().get(customerUrl, context);

      if (customerResponse.data is Map<String, dynamic>) {
        List<Map<String, dynamic>> allCustomersList = 
            List<Map<String, dynamic>>.from(customerResponse.data['data']);

        // Fetch all orders to check for active ones
        final String orderUrl = "${Urls.ordersSave}/$id?pageNumber=1&pageSize=100&searchKeyword=";
        final orderResponse = await ApiService().get(orderUrl, context);

        if (orderResponse.data is Map<String, dynamic>) {
          List<Map<String, dynamic>> allOrders = 
              List<Map<String, dynamic>>.from(orderResponse.data['data']);

          // Get customer IDs who have active orders (not completed)
          Set<int> activeCustomerIds = {};
          final now = DateTime.now();
          
          for (var order in allOrders) {
            if (order['status']?.toString().toLowerCase() != 'completed') {
              // Check if order has future delivery date or is in progress
              bool isActive = true;
              if (order['items'] != null && order['items'] is List) {
                final items = order['items'] as List;
                if (items.isNotEmpty) {
                  final firstItem = items.first;
                  if (firstItem['delivery_date'] != null) {
                    try {
                      final deliveryDate = DateTime.parse(firstItem['delivery_date']);
                      isActive = deliveryDate.isAfter(now.subtract(Duration(days: 30))); // Active if delivery is within last 30 days or future
                    } catch (e) {
                      // If date parsing fails, consider it active
                      isActive = true;
                    }
                  }
                }
              }
              
              if (isActive) {
                activeCustomerIds.add(order['customerId'] ?? 0);
              }
            }
          }

          // Filter customers who have active orders
          List<Map<String, dynamic>> activeCustomers = allCustomersList
              .where((customer) => activeCustomerIds.contains(customer['customerId']))
              .toList();

          // Sort alphabetically
          activeCustomers.sort((a, b) {
            String nameA = (a['name'] ?? '').toString().toLowerCase();
            String nameB = (b['name'] ?? '').toString().toLowerCase();
            return nameA.compareTo(nameB);
          });

          setState(() {
            customers = activeCustomers;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _fetchcustomerData() async {
    if (isLoading || !hasMoreData) return;

    int? id = GlobalVariables.shopIdGet;
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String requestUrl =
        "${Urls.customer}/$id?pageNumber=$pageNumber&pageSize=$pageSize&searchKeyword=${searchKeywordController.text}";

    try {
      if (_isInitialFetch && pageNumber == 1) {
        Future.delayed(Duration.zero, () => showLoader(context));
      }
      final response = await ApiService().get(requestUrl, context);
      if (_isInitialFetch && pageNumber == 1) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }

      if (response.data is Map<String, dynamic>) {
        List<dynamic> fetchedCustomers = response.data['data'];
        List<Map<String, dynamic>> newCustomers = List<Map<String, dynamic>>.from(fetchedCustomers);
        
        setState(() {
          customers.addAll(newCustomers);
          allCustomers.addAll(newCustomers);
          if (fetchedCustomers.length < pageSize) {
            hasMoreData = false;
          } else {
            pageNumber++;
          }
          isLoading = false;
          _isInitialFetch = false;
        });
        
        // Sort alphabetically after adding new data
        if (selectedFilter == 'All') {
          _sortCustomersAlphabetically();
          setState(() {});
        }
      } else {
        CustomSnackbar.showSnackbar(
          context,
          'Customer not found',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (_isInitialFetch && pageNumber == 1) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }
      CustomSnackbar.showSnackbar(
        context,
        'Failed to load customers',
        duration: Duration(seconds: 2),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAddcustomerModal(BuildContext context) async {
    final result =
        await Navigator.of(context).pushNamed(AppRoutes.customerInfo);
    if (result == true) _resetAndFetch();
  }

  void _showEditcustomerModal(BuildContext context, int? customerId) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.customerInfo,
      arguments: customerId,
    );
    if (result == true) _resetAndFetch();
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        'Phone number not available',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Clean the phone number - remove spaces, dashes, and other non-digit characters
    // Keep + if present at the start
    String cleanedNumber = phoneNumber.trim();
    if (cleanedNumber.startsWith('+')) {
      cleanedNumber = '+' + cleanedNumber.substring(1).replaceAll(RegExp(r'[^\d]'), '');
    } else {
      cleanedNumber = cleanedNumber.replaceAll(RegExp(r'[^\d]'), '');
    }

    if (cleanedNumber.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        'Invalid phone number',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Create tel: URL
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        CustomSnackbar.showSnackbar(
          context,
          'Cannot make phone call',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      CustomSnackbar.showSnackbar(
        context,
        'Error making phone call: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Commonheader(
          title: 'Customer',
          titleSpacing: 15,
          showBackArrow: false,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                onPressed: () => _showAddcustomerModal(context),
                icon: const Icon(Icons.add, color: ColorPalatte.primary),
                label: const Text('Add Customer',
                    style: TextStyle(color: ColorPalatte.primary)),
              ),
            ),
          ],
        ),
        backgroundColor: ColorPalatte.white,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: searchKeywordController,
                decoration: InputDecoration(
                  hintText: "Search customer...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _onSearchChanged(),
              ),
            ),
            // Filter buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              height: 50,
              child: Row(
                children: [
                  Text(
                    'Filter:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Newly Created'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active Customer'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: customers.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: customers.length + (hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == customers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: ColorPalatte.primary,
                                    strokeWidth: 2,
                                  )),
                            ),
                          );
                        }

                        final customer = customers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: ColorPalatte.primary.withOpacity(0.8),
                              radius: 24,
                              child: Text(
                                customer['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              customer['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ID: ${customer['customerId']} | Mobile: ${customer['mobile'] ?? 'N/A'}",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                if (selectedFilter == 'Newly Created' && customer['createdAt'] != null)
                                  Text(
                                    "Created: ${_formatDate(customer['createdAt'])}",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (selectedFilter == 'Active Customer')
                                  Text(
                                    "Has active orders",
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Call icon - only visible on mobile
                                if (!kIsWeb && customer['mobile'] != null && customer['mobile'].toString().isNotEmpty)
                                  InkWell(
                                    onTap: () => _makePhoneCall(customer['mobile']),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.phone,
                                        size: 18,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                // Arrow icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: ColorPalatte.primary,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (customer.isNotEmpty) {
                                _showEditcustomerModal(
                                    context, customer['customerId']);
                              }
                            },
                          ),
                        );
                      },
                    ),
            )
          ],
        ));
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = selectedFilter == filter;
    return FilterChip(
      label: Text(
        filter,
        style: TextStyle(
          color: isSelected ? Colors.white : ColorPalatte.primary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          _applyFilter(filter);
        }
      },
      selectedColor: ColorPalatte.primary,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? ColorPalatte.primary : Colors.grey.shade300,
      ),
      showCheckmark: false,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchKeywordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
