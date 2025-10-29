import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/GlobalVariables.dart';
import 'package:tailorapp/Routes/App_route.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = false;
  bool hasMoreData = true;
  TextEditingController searchKeywordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  int pageNumber = 1;
  final int pageSize = 10;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize listeners in initState
    _scrollController.addListener(_scrollListener);
    searchKeywordController.addListener(_onSearchChanged);
    _tabController.addListener(_onTabChanged);
    // Fetch initial data
    fetchOrderApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    searchKeywordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging && mounted) {
      setState(() {
        currentTabIndex = _tabController.index;
        // Apply filtering to existing orders instead of clearing them
        _applyClientSideFiltering();
      });
    }
  }

  void _scrollListener() {
    if (!isLoading &&
        hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      fetchOrderApi();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          orders.clear();
          filteredOrders.clear();
          pageNumber = 1;
          hasMoreData = true;
        });
        fetchOrderApi();
      }
    });
  }


  void _applyClientSideFiltering() {
    switch (currentTabIndex) {
      case 0: // All Orders
        filteredOrders = orders;
        break;
      case 1: // Received
        filteredOrders = orders.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'received';
        }).toList();
        break;
      case 2: // In Progress
        filteredOrders = orders.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'in-progress' || status == 'in_progress';
        }).toList();
        break;
      case 3: // Completed
        filteredOrders = orders.where((order) {
          final status = order['status']?.toString().toLowerCase();
          return status == 'completed' || status == 'delivered';
        }).toList();
        break;
      default:
        filteredOrders = orders;
    }
  }

  String _getStatusForTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // All Orders
        return '';
      case 1: // Received
        return 'received';
      case 2: // In Progress
        return 'in-progress'; // Use backend format
      case 3: // Completed
        return 'completed';
      default:
        return '';
    }
  }

  DateTime? _getDeliveryDate(Map<String, dynamic> order) {
    try {
      // Check if order has items with delivery dates
      if (order['items'] != null && order['items'] is List) {
        final items = order['items'] as List;
        if (items.isNotEmpty) {
          final firstItem = items.first;
          if (firstItem['delivery_date'] != null) {
            return DateTime.parse(firstItem['delivery_date']);
          }
        }
      }
      
      // Fallback to advanceReceivedDate or createdAt
      if (order['advanceReceivedDate'] != null) {
        return DateTime.parse(order['advanceReceivedDate']);
      }
      
      if (order['createdAt'] != null) {
        return DateTime.parse(order['createdAt']);
      }
      
      return null;
    } catch (e) {
      print('Error parsing delivery date: $e');
      return null;
    }
  }

  void fetchOrderApi() async {
    if (isLoading || !hasMoreData || !mounted) return;

    setState(() {
      isLoading = true;
    });

    int? shopId = GlobalVariables.shopIdGet;
    try {
      // Always fetch all orders without status filter (backend not deployed yet)
      String url =
          "${Urls.ordersSave}/$shopId?pageNumber=$pageNumber&pageSize=$pageSize&searchKeyword=${searchKeywordController.text}";
      
      final response = await ApiService().get(url, context);

      if (!mounted) return; // Check if widget is still mounted

      if (response.data != null && response.data['data'] != null) {
        List<Map<String, dynamic>> newOrders =
            List<Map<String, dynamic>>.from(response.data['data']);

        setState(() {
          orders.addAll(newOrders);
          // Apply client-side filtering based on current tab
          _applyClientSideFiltering();
          isLoading = false;
          if (newOrders.length < pageSize) {
            hasMoreData = false;
          } else {
            pageNumber++;
          }
        });
      } else {
        setState(() {
          isLoading = false;
          hasMoreData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search Orders",
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: ColorPalatte.borderGray,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      controller: searchKeywordController,
                      onSubmitted: (_) => _onSearchChanged(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: ColorPalatte.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    height: 45,
                    width: 45,
                    child: IconButton(
                      icon: const Icon(Icons.filter_list,
                          color: Colors.white, size: 25),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Received'),
                Tab(text: 'In Progress'),
                Tab(text: 'Completed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderListForTab(0), // All
                  _buildOrderListForTab(1), // Received
                  _buildOrderListForTab(2), // In Progress
                  _buildOrderListForTab(3), // Completed
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 18,
          right: 18,
          child: SizedBox(
            height: 45,
            width: 45,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.createOrder).then((_) {
                  setState(() {
                    orders.clear();
                    filteredOrders.clear();
                    pageNumber = 1;
                    hasMoreData = true;
                  });
                  fetchOrderApi();
                });
              },
              backgroundColor: ColorPalatte.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ----- Additional widgets ----
  Widget _buildOrderListForTab(int tabIndex) {
    // Since we're filtering at API level, all tabs show the same data
    // but only the current tab shows pagination controls
    List<Map<String, dynamic>> ordersToShow = filteredOrders;

    if (ordersToShow.isEmpty && !isLoading) {
      String emptyMessage;
      switch (tabIndex) {
        case 0:
          emptyMessage = "No orders available";
          break;
        case 1:
          emptyMessage = "No received orders";
          break;
        case 2:
          emptyMessage = "No orders in progress";
          break;
        case 3:
          emptyMessage = "No completed orders";
          break;
        default:
          emptyMessage = "No orders available";
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: tabIndex == currentTabIndex ? _scrollController : null,
      itemCount: ordersToShow.length + (hasMoreData && tabIndex == currentTabIndex ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == ordersToShow.length && hasMoreData && tabIndex == currentTabIndex) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: ColorPalatte.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        return _buildOrderCard(ordersToShow[index]);
      },
    );
  }


  Widget _buildOrderList(List<Map<String, dynamic>> orderList) {
    if (orderList.isEmpty) {
      return const Center(
        child: Text("No orders available",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: orderList.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orderList[index]);
      },
    );
  }

  // Order Card Widget
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final createdAt =
        DateTime.parse(order['createdAt'] ?? DateTime.now().toString());
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdAt);
    final price = order['estimationCost']?.toString() ?? '0';
    final formattedPrice =
        '₹${NumberFormat('#,##0').format(double.parse(price))}';
    
    final deliveryDate = _getDeliveryDate(order);
    final formattedDeliveryDate = deliveryDate != null
        ? DateFormat('MMM dd, yyyy').format(deliveryDate)
        : 'Not set';
    
    final status = order['status']?.toString() ?? 'In Progress';
    final isUrgent = order['urgent'] == true;
    final isOverdue = deliveryDate != null && 
                     deliveryDate.isBefore(DateTime.now()) && 
                     status.toLowerCase() != 'completed';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.orderDetailsScreen,
          arguments: order['orderId'],
        ).then((_) {
          // Reset state and fetch new data when returning from orderDetailsScreen
          setState(() {
            orders.clear();
            pageNumber = 1;
            hasMoreData = true;
          });
          fetchOrderApi();
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: isOverdue 
                      ? Colors.red 
                      : isUrgent 
                          ? Colors.orange 
                          : status.toLowerCase() == 'completed' 
                              ? Colors.green 
                              : ColorPalatte.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ORD-${order['orderId']?.toString().padLeft(3, '0') ?? '000'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer: ${order['customer_name'] ?? '#${order['customerId']?.toString() ?? 'Unknown'}'}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order['quantity'] ?? 0} items | Created: $formattedDate',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Delivery: $formattedDeliveryDate',
                      style: TextStyle(
                        color: isOverdue ? Colors.red.shade700 : Colors.grey[600], 
                        fontSize: 12,
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedPrice,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.toLowerCase() == 'completed' 
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: status.toLowerCase() == 'completed' 
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
