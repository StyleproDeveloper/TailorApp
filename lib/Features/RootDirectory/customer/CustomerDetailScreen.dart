import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/GlobalVariables.dart';
import 'package:tailorapp/Routes/App_route.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? customerData;
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoadingCustomer = true;
  bool isLoadingOrders = true;
  late TabController _tabController;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchCustomerDetails();
    _fetchCustomerOrders();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        currentTabIndex = _tabController.index;
        _applyOrderFilter();
      });
    }
  }

  void _applyOrderFilter() {
    switch (currentTabIndex) {
      case 0: // All
        filteredOrders = allOrders;
        break;
      case 1: // Received
        filteredOrders = allOrders.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'received';
        }).toList();
        break;
      case 2: // In Progress
        filteredOrders = allOrders.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'in-progress' || status == 'in_progress';
        }).toList();
        break;
      case 3: // Completed
        filteredOrders = allOrders.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'completed' || status == 'delivered';
        }).toList();
        break;
      default:
        filteredOrders = allOrders;
    }
  }

  Future<void> _fetchCustomerDetails() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      CustomSnackbar.showSnackbar(
        context,
        "Shop ID is missing",
        duration: Duration(seconds: 2),
      );
      setState(() => isLoadingCustomer = false);
      return;
    }

    try {
      final requestUrl = "${Urls.customer}/$shopId/${widget.customerId}";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data != null) {
        setState(() {
          customerData = response.data;
          isLoadingCustomer = false;
        });
      } else {
        setState(() => isLoadingCustomer = false);
      }
    } catch (e) {
      setState(() => isLoadingCustomer = false);
      CustomSnackbar.showSnackbar(
        context,
        'Failed to load customer details',
        duration: Duration(seconds: 2),
      );
    }
  }

  Future<void> _fetchCustomerOrders() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      setState(() => isLoadingOrders = false);
      return;
    }

    try {
      // Fetch all orders and filter by customerId on client side
      // Since backend might not support customerId filter directly
      final requestUrl = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=1000";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data != null && response.data['data'] != null) {
        List<Map<String, dynamic>> allOrdersList = 
            List<Map<String, dynamic>>.from(response.data['data']);
        
        // Filter orders by customerId
        List<Map<String, dynamic>> customerOrders = allOrdersList
            .where((order) => order['customerId'] == widget.customerId)
            .toList();
        
        // Sort by creation date (newest first)
        customerOrders.sort((a, b) {
          try {
            DateTime dateA = DateTime.parse(a['createdAt'] ?? DateTime.now().toString());
            DateTime dateB = DateTime.parse(b['createdAt'] ?? DateTime.now().toString());
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        
        setState(() {
          allOrders = customerOrders;
          isLoadingOrders = false;
          _applyOrderFilter();
        });
      } else {
        setState(() => isLoadingOrders = false);
      }
    } catch (e) {
      setState(() => isLoadingOrders = false);
      print('Error fetching customer orders: $e');
    }
  }

  void _navigateToEditCustomer() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.customerInfo,
      arguments: widget.customerId,
    );
    if (result == true) {
      _fetchCustomerDetails();
    }
  }

  void _navigateToOrderDetails(int orderId) {
    Navigator.pushNamed(
      context,
      AppRoutes.orderDetailsScreen,
      arguments: orderId,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '₹0';
    return '₹${amount.toStringAsFixed(2)}';
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'completed' || lowerStatus == 'delivered') {
      return Colors.green;
    } else if (lowerStatus == 'in-progress' || lowerStatus == 'in_progress') {
      return Colors.blue;
    } else if (lowerStatus == 'received') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Commonheader(
        title: 'Customer Details',
        actions: [
          if (GlobalVariables.hasPermission('editCustomer'))
            IconButton(
              icon: Icon(Icons.edit, color: ColorPalatte.primary),
              onPressed: _navigateToEditCustomer,
              tooltip: 'Edit Customer',
            ),
        ],
      ),
      backgroundColor: ColorPalatte.white,
      body: isLoadingCustomer
          ? Center(child: CircularProgressIndicator())
          : customerData == null
              ? Center(child: Text('Customer not found'))
              : Column(
                  children: [
                    // Customer Information Card
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: ColorPalatte.primary.withOpacity(0.8),
                                radius: 30,
                                child: Text(
                                  (customerData!['name']?[0] ?? 'C').toString().toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerData!['name'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: Fonts.Bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'ID: ${customerData!['customerId'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Divider(),
                          SizedBox(height: 8),
                          _buildInfoRow(Icons.phone, 'Mobile', customerData!['mobile'] ?? 'N/A'),
                          if (customerData!['secondaryMobile'] != null && 
                              customerData!['secondaryMobile'].toString().isNotEmpty)
                            _buildInfoRow(Icons.phone, 'Secondary Mobile', 
                                customerData!['secondaryMobile'] ?? 'N/A'),
                          if (customerData!['email'] != null && 
                              customerData!['email'].toString().isNotEmpty)
                            _buildInfoRow(Icons.email, 'Email', customerData!['email'] ?? 'N/A'),
                          if (customerData!['addressLine1'] != null && 
                              customerData!['addressLine1'].toString().isNotEmpty)
                            _buildInfoRow(Icons.location_on, 'Address', 
                                customerData!['addressLine1'] ?? 'N/A'),
                          if (customerData!['dateOfBirth'] != null && 
                              customerData!['dateOfBirth'].toString().isNotEmpty)
                            _buildInfoRow(Icons.cake, 'Date of Birth', 
                                _formatDate(customerData!['dateOfBirth'])),
                          if (customerData!['gender'] != null)
                            _buildInfoRow(Icons.person, 'Gender', 
                                customerData!['gender'].toString().toUpperCase()),
                        ],
                      ),
                    ),
                    
                    // Orders Section
                    Expanded(
                      child: Column(
                        children: [
                          // Tab Bar
                          Container(
                            color: Colors.grey.shade100,
                            child: TabBar(
                              controller: _tabController,
                              labelColor: ColorPalatte.primary,
                              unselectedLabelColor: Colors.grey.shade600,
                              indicatorColor: ColorPalatte.primary,
                              tabs: [
                                Tab(text: 'All (${allOrders.length})'),
                                Tab(text: 'Received (${allOrders.where((o) => o['status']?.toString().toLowerCase() == 'received').length})'),
                                Tab(text: 'In Progress (${allOrders.where((o) => ['in-progress', 'in_progress'].contains(o['status']?.toString().toLowerCase())).length})'),
                                Tab(text: 'Completed (${allOrders.where((o) => ['completed', 'delivered'].contains(o['status']?.toString().toLowerCase())).length})'),
                              ],
                            ),
                          ),
                          
                          // Orders List
                          Expanded(
                            child: isLoadingOrders
                                ? Center(child: CircularProgressIndicator())
                                : filteredOrders.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 64,
                                              color: Colors.grey.shade400,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No orders found',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: EdgeInsets.all(16),
                                        itemCount: filteredOrders.length,
                                        itemBuilder: (context, index) {
                                          final order = filteredOrders[index];
                                          return _buildOrderCard(order);
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ColorPalatte.primary),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateOrderTotal(Map<String, dynamic> order) {
    try {
      // Calculate items total
      final items = order['items'] as List<dynamic>? ?? [];
      double itemsTotal = 0.0;
      for (var item in items) {
        itemsTotal += (item['amount'] ?? 0).toDouble();
      }

      // Calculate additional costs total
      final additionalCosts = order['additionalCosts'] as List<dynamic>? ?? [];
      double additionalCostsTotal = 0.0;
      for (var cost in additionalCosts) {
        additionalCostsTotal += (cost['additionalCost'] ?? 0).toDouble();
      }

      // Calculate subtotal
      double subtotal = itemsTotal + additionalCostsTotal;
      
      // Fallback to estimationCost if subtotal is 0
      if (subtotal == 0.0 && order['estimationCost'] != null) {
        subtotal = (order['estimationCost'] ?? 0).toDouble();
      }

      // Apply discount
      final discount = (order['discount'] ?? 0).toDouble();
      final subtotalAfterDiscount = (subtotal - discount).clamp(0.0, double.infinity);

      // Add courier charge
      final courierCharge = (order['courierCharge'] ?? 0).toDouble();

      // Calculate GST (18% on discounted subtotal if GST is enabled)
      final gstAmount = order['gst'] == true ? (subtotalAfterDiscount * 0.18) : 0.0;

      // Final total: discounted subtotal + courier + GST
      final total = subtotalAfterDiscount + courierCharge + gstAmount;
      
      return total;
    } catch (e) {
      print('Error calculating order total: $e');
      // Fallback to totalAmount if calculation fails
      return (order['totalAmount'] ?? 0.0).toDouble();
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? 'N/A';
    final status = order['status']?.toString() ?? 'N/A';
    final items = order['items'] as List<dynamic>? ?? [];
    final totalAmount = _calculateOrderTotal(order);
    final deliveryDate = _getDeliveryDate(order);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToOrderDetails(orderId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #$orderId',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: Fonts.Bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Text(
                    '${items.length} item${items.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.currency_rupee, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Text(
                    _formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorPalatte.primary,
                    ),
                  ),
                ],
              ),
              if (deliveryDate != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Text(
                      'Delivery: ${_formatDate(deliveryDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _getDeliveryDate(Map<String, dynamic> order) {
    try {
      if (order['deliveryDate'] != null) {
        return order['deliveryDate'].toString();
      }
      final items = order['items'] as List<dynamic>? ?? [];
      if (items.isNotEmpty) {
        final firstItem = items.first;
        if (firstItem['delivery_date'] != null) {
          return firstItem['delivery_date'].toString();
        }
      }
    } catch (e) {
      print('Error getting delivery date: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
