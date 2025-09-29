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

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        currentTabIndex = _tabController.index;
      });
      _filterOrdersByTab();
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
      setState(() {
        orders.clear();
        pageNumber = 1;
        hasMoreData = true;
      });
      fetchOrderApi();
    });
  }

  void _filterOrdersByTab() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    setState(() {
      switch (currentTabIndex) {
        case 0: // Active - Future delivery dates
          filteredOrders = orders.where((order) {
            final deliveryDate = _getDeliveryDate(order);
            return deliveryDate != null && 
                   deliveryDate.isAfter(now) && 
                   order['status']?.toString().toLowerCase() != 'completed';
          }).toList();
          break;
        case 1: // Past Due - Past delivery dates and not completed
          filteredOrders = orders.where((order) {
            final deliveryDate = _getDeliveryDate(order);
            return deliveryDate != null && 
                   deliveryDate.isBefore(now) && 
                   order['status']?.toString().toLowerCase() != 'completed';
          }).toList();
          break;
        case 2: // Upcoming - Next 7 days
          filteredOrders = orders.where((order) {
            final deliveryDate = _getDeliveryDate(order);
            return deliveryDate != null && 
                   deliveryDate.isAfter(now) && 
                   deliveryDate.isBefore(nextWeek) &&
                   order['status']?.toString().toLowerCase() != 'completed';
          }).toList();
          break;
        case 3: // Completed - Status is completed
          filteredOrders = orders.where((order) {
            return order['status']?.toString().toLowerCase() == 'completed';
          }).toList();
          break;
        default:
          filteredOrders = orders;
      }
    });
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
    if (isLoading || !hasMoreData) return;

    setState(() {
      isLoading = true;
    });

    int? shopId = GlobalVariables.shopIdGet;
    try {
      String url =
          "${Urls.ordersSave}/$shopId?pageNumber=$pageNumber&pageSize=$pageSize&searchKeyword=${searchKeywordController.text}";
      final response = await ApiService().get(url, context);

      if (response.data != null && response.data['data'] != null) {
        List<Map<String, dynamic>> newOrders =
            List<Map<String, dynamic>>.from(response.data['data']);

        setState(() {
          orders.addAll(newOrders);
          isLoading = false;
          if (newOrders.length < pageSize) {
            hasMoreData = false;
          } else {
            pageNumber++;
          }
        });
        _filterOrdersByTab(); // Filter orders after fetching
      } else {
        setState(() {
          isLoading = false;
          hasMoreData = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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
                Tab(text: 'Active'),
                Tab(text: 'Past Due'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderListForTab(0), // Active
                  _buildOrderListForTab(1), // Past Due
                  _buildOrderListForTab(2), // Upcoming
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
    // Use filteredOrders for the current tab, or orders for initial load
    List<Map<String, dynamic>> ordersToShow = 
        tabIndex == currentTabIndex ? filteredOrders : orders;
    
    if (tabIndex != currentTabIndex) {
      // Force filter for the specific tab
      _filterOrdersForSpecificTab(tabIndex);
      ordersToShow = filteredOrders;
    }

    if (ordersToShow.isEmpty && !isLoading) {
      String emptyMessage;
      switch (tabIndex) {
        case 0:
          emptyMessage = "No active orders";
          break;
        case 1:
          emptyMessage = "No past due orders";
          break;
        case 2:
          emptyMessage = "No upcoming orders";
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

  void _filterOrdersForSpecificTab(int tabIndex) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    switch (tabIndex) {
      case 0: // Active - Future delivery dates
        filteredOrders = orders.where((order) {
          final deliveryDate = _getDeliveryDate(order);
          return deliveryDate != null && 
                 deliveryDate.isAfter(now) && 
                 order['status']?.toString().toLowerCase() != 'completed';
        }).toList();
        break;
      case 1: // Past Due - Past delivery dates and not completed
        filteredOrders = orders.where((order) {
          final deliveryDate = _getDeliveryDate(order);
          return deliveryDate != null && 
                 deliveryDate.isBefore(now) && 
                 order['status']?.toString().toLowerCase() != 'completed';
        }).toList();
        break;
      case 2: // Upcoming - Next 7 days
        filteredOrders = orders.where((order) {
          final deliveryDate = _getDeliveryDate(order);
          return deliveryDate != null && 
                 deliveryDate.isAfter(now) && 
                 deliveryDate.isBefore(nextWeek) &&
                 order['status']?.toString().toLowerCase() != 'completed';
        }).toList();
        break;
      case 3: // Completed - Status is completed
        filteredOrders = orders.where((order) {
          return order['status']?.toString().toLowerCase() == 'completed';
        }).toList();
        break;
      default:
        filteredOrders = orders;
    }
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

  @override
  void dispose() {
    _scrollController.dispose();
    searchKeywordController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
