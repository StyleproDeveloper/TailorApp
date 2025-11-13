import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/OrderDetail/OrderDetailStyles.dart';
import 'package:tailorapp/GlobalVariables.dart';
import 'package:tailorapp/Routes/App_route.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? order;
  bool isLoading = true;
  dynamic orderId;
  Map<int, String> dressTypeNames = {}; // Cache for dress type names
  Map<int, List<Map<String, dynamic>>> orderItemMedia = {}; // Media for each order item (key: orderItemId)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        setState(() {
          orderId = args;
        });
        fetchProductDetail();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  String _beautifyKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _fetchDressTypeNames() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final String requestUrl = "${Urls.addDress}/$shopId?pageNumber=1&pageSize=100";
      final response = await ApiService().get(requestUrl, context);
      
      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        List<dynamic> dressTypes = response.data['data'];
        Map<int, String> names = {};
        
        for (var dressType in dressTypes) {
          names[dressType['dressTypeId']] = dressType['name'];
        }
        
        if (mounted) {
          setState(() {
            dressTypeNames = names;
          });
        }
      }
    } catch (e) {
      print('Error fetching dress type names: $e');
    }
  }

  // Fetch media for all order items
  Future<void> _fetchOrderItemMedia() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null || orderId == null || order == null) return;

    try {
      final items = order?['items'] as List<dynamic>? ?? [];
      Map<int, List<Map<String, dynamic>>> mediaMap = {};

      // Fetch media for each order item
      for (var item in items) {
        final orderItemId = item['orderItemId'];
        if (orderItemId != null) {
          try {
            final String requestUrl = "${Urls.orderMedia}/$shopId/$orderId/$orderItemId";
            final response = await ApiService().get(requestUrl, context);
            
            if (response.data != null && response.data['data'] != null) {
              final mediaList = response.data['data'] as List<dynamic>;
              mediaMap[orderItemId] = mediaList.cast<Map<String, dynamic>>();
            }
          } catch (e) {
            print('Error fetching media for orderItemId $orderItemId: $e');
            // Continue with other items even if one fails
          }
        }
      }

      if (mounted) {
        setState(() {
          orderItemMedia = mediaMap;
        });
      }
    } catch (e) {
      print('Error fetching order item media: $e');
    }
  }

  void fetchProductDetail() async {
    showLoader(context);
    int? shopId = GlobalVariables.shopIdGet;
    if (orderId == null || shopId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      String url =
          "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=10&orderId=$orderId";
      final response = await ApiService().get(url, context);
      hideLoader(context);

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> orders = response.data['data'];
        if (orders.isNotEmpty) {
          setState(() {
            order = orders[0] as Map<String, dynamic>;
            isLoading = false;
          });
          // Fetch dress type names after order is loaded
          _fetchDressTypeNames();
          // Fetch media for all order items
          _fetchOrderItemMedia();
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      hideLoader(context);
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return Scaffold(
        backgroundColor: ColorPalatte.white,
        appBar: Commonheader(title: 'Order Details'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No order data available'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchProductDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(
        title: 'Order Details',
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.createOrder,
                  arguments: orderId,
                );
              },
              icon: const Icon(
                Icons.edit,
                color: ColorPalatte.primary,
                size: 25,
              ),
              label: Text(
                Textstring().edit,
                style: Orderdetailstyles.editBtn,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            ..._buildOrderItems(),
            ..._buildAdditionalCostItems(),
            const SizedBox(height: 16),
            _buildCostSummary(),
            const SizedBox(height: 16),
            _buildDeliveryInfo(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB28C6E),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  CustomSnackbar.showSnackbar(
                    context,
                    'Tracking feature Under Development.',
                    duration: Duration(seconds: 1),
                  );
                },
                child: const Text(
                  'Track Order',
                  style: Orderdetailstyles.trackOrderBtnText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDeliveryDate() {
    // First try to get delivery date from order level (earliest date from all items)
    final orderDeliveryDate = order?['deliveryDate']?.toString();
    if (orderDeliveryDate != null && orderDeliveryDate.isNotEmpty) {
      try {
        final date = DateTime.parse(orderDeliveryDate);
        return DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        return orderDeliveryDate;
      }
    }
    
    // Fallback: Get earliest delivery date from items if order level date is not set
    final items = order?['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return 'Not Set';
    }
    
    // Get delivery dates from all items
    final deliveryDates = items
        .map((item) => item['delivery_date']?.toString())
        .where((date) => date != null && date!.isNotEmpty)
        .map((date) => date!)
        .toList();
    
    if (deliveryDates.isEmpty) {
      return 'Not Set';
    }
    
    // Sort dates and get the earliest one
    deliveryDates.sort();
    
    try {
      final date = DateTime.parse(deliveryDates[0]);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return deliveryDates[0];
    }
  }

  Widget _buildHeader() {
    final createdAt =
        DateTime.parse(order?['createdAt'] ?? DateTime.now().toString());
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdAt);
    final status = order?['status'] ?? 'In Progress';
    final isUrgent = order?['urgent'] == true;
    final advanceReceivedDate = order?['advanceReceivedDate'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(
            order?['advanceReceivedDate'] ?? DateTime.now().toString()))
        : 'Not Received';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Name: ${order?['customer_name'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUrgent ? Colors.red.shade400 : const Color(0xFFC9A88E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isUrgent ? 'Urgent - $status' : status,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Order #ORD${order?['orderId']?.toString().padLeft(3, '0') ?? '000'}',
          style: Orderdetailstyles.subTitles,
        ),
        const SizedBox(height: 4),
        Text(
          'Order Date: $formattedDate',
          style: Orderdetailstyles.subTitles,
        ),
        const SizedBox(height: 4),
        Text(
          'Delivery Date: ${_getDeliveryDate()}',
          style: Orderdetailstyles.subTitles,
        ),
      ],
    );
  }

// list for order items
  List<Widget> _buildOrderItems() {
    final items = order?['items'] as List<dynamic>? ?? [];

    String type = '';
    final stitchingType = order?['stitchingType'];
    if (stitchingType == 1) {
      type = 'Stitching';
    } else if (stitchingType == 2) {
      type = 'Alter';
    } else if (stitchingType == 3) {
      type = 'Material';
    }

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final measurementList = item['measurement'] as List<dynamic>? ?? [];
      final measurement = measurementList.isNotEmpty
          ? measurementList[0] as Map<String, dynamic>
          : {};

      // Always use item amount for cost display
      final String itemCost = (item['amount']?.toString() ?? '0');

      if (measurement.isNotEmpty) {
        final measurementFields = measurement.entries
            .where((e) => ![
                  '_id',
                  'orderItemId',
                  'orderItemMeasurementId',
                  'dressTypeId',
                  'customerId',
                  'orderId',
                  'owner',
                  'createdAt',
                  'updatedAt'
                ].contains(e.key))
            .map((e) => MapEntry(_beautifyKey(e.key), e.value.toString()));

        final dressTypeId = item['dressTypeId'];
        final dressTypeName = dressTypeNames[dressTypeId] ?? 'Dress Type $dressTypeId';
        
        final orderItemId = item['orderItemId'];
        final itemMedia = orderItemId != null ? orderItemMedia[orderItemId] : null;
        
        return Column(
          children: [
            _buildItemCard(
              title: 'Item #${index + 1} - $dressTypeName',
              type: type,
              measurements: Map.fromEntries(measurementFields),
              cost: itemCost,
              orderItemId: orderItemId,
              item: item,
            ),
            // Display media for this item
            if (itemMedia != null && itemMedia.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildItemMedia(itemMedia),
            ],
          ],
        );
      } else {
        final orderItemId = item['orderItemId'];
        final itemMedia = orderItemId != null ? orderItemMedia[orderItemId] : null;
        
        return Column(
          children: [
            _buildSimpleItem(
              title: 'Item #${index + 1}',
              description: item['specialInstructions']?.toString() ?? 'No details',
              cost: itemCost,
              orderItemId: orderItemId,
              item: item,
            ),
            // Display media for this item
            if (itemMedia != null && itemMedia.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildItemMedia(itemMedia),
            ],
          ],
        );
      }
    }).toList();
  }

  // Build additional cost items display
  List<Widget> _buildAdditionalCostItems() {
    final additionalCosts = order?['additionalCosts'] as List<dynamic>? ?? [];
    
    if (additionalCosts.isEmpty) {
      return [];
    }
    
    return [
      const SizedBox(height: 16),
      const Text(
        'Additional Costs',
        style: Orderdetailstyles.titleHeaders,
      ),
      const SizedBox(height: 8),
      ...additionalCosts.asMap().entries.map((entry) {
        final index = entry.key;
        final cost = entry.value as Map<String, dynamic>;
        final description = cost['additionalCostName']?.toString() ?? 'Additional Cost';
        final amount = cost['additionalCost']?.toString() ?? '0';
        
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(width: 0.5, color: Colors.grey),
          ),
          color: Colors.white,
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##0').format(double.tryParse(amount) ?? 0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ];
  }

  Widget _buildItemCard({
    required String title,
    required String type,
    required Map<String, String> measurements,
    required String cost,
    int? orderItemId,
    Map<String, dynamic>? item,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(width: 0.5, color: Colors.grey),
      ),
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        // mark is here...!!!
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Orderdetailstyles.titleHeadersSide,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '₹$cost',
              style: Orderdetailstyles.subTitles,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ColorPalatte.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: Orderdetailstyles.ordertypeText,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.2,
                  children: measurements.entries.map((e) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ColorPalatte.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _buildDeliveryStatusSection(orderItemId, item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleItem({
    required String title,
    required String description,
    required String cost,
    int? orderItemId,
    Map<String, dynamic>? item,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(width: 1, color: Colors.grey),
      ),
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Orderdetailstyles.subTitles,
            ),
            Text(
              '₹$cost',
              style: Orderdetailstyles.subTitles,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _buildDeliveryStatusSection(orderItemId, item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() {
    // Calculate subtotal by summing all item amounts
    final items = order?['items'] as List<dynamic>? ?? [];
    double itemsTotal = 0.0;
    for (var item in items) {
      final amount = (item['amount'] ?? 0).toDouble();
      itemsTotal += amount;
    }
    
    // Add additional costs from order data
    final additionalCosts = order?['additionalCosts'] as List<dynamic>? ?? [];
    double additionalCostsTotal = 0.0;
    for (var cost in additionalCosts) {
      final amount = (cost['additionalCost'] ?? 0).toDouble();
      additionalCostsTotal += amount;
    }
    
    // Calculate subtotal: items + additional costs
    double subtotalValue = itemsTotal + additionalCostsTotal;
    
    // If no additional costs in data but estimationCost is higher than items total,
    // use estimationCost (which includes additional costs)
    if (additionalCostsTotal == 0.0 && 
        order?['estimationCost'] != null && 
        itemsTotal > 0.0) {
      final estimationCost = (order?['estimationCost'] ?? 0).toDouble();
      // If estimationCost is higher than items total, the difference is likely additional costs
      if (estimationCost > itemsTotal) {
        subtotalValue = estimationCost;
      } else {
        subtotalValue = itemsTotal;
      }
    } else if (subtotalValue == 0.0 && order?['estimationCost'] != null) {
      // Fallback: use estimationCost if no items have amounts
      subtotalValue = (order?['estimationCost'] ?? 0).toDouble();
    }
    
    final subtotal = subtotalValue.toStringAsFixed(0);
    final courierCharge = order?['courierCharge']?.toString() ?? '0';
    final gst = order?['gst'] == true
        ? (subtotalValue * 0.18).toStringAsFixed(0)
        : '0';
    final advanceReceived = order?['advancereceived']?.toString() ?? '0';
    final total = (subtotalValue +
            double.parse(courierCharge) +
            double.parse(gst))
        .toStringAsFixed(0);
    final balance = (double.parse(total) - double.parse(advanceReceived))
        .toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Cost Summary',
          style: Orderdetailstyles.titleHeaders,
        ),
        const SizedBox(height: 8),
        _buildSummaryRow('Subtotal', subtotal),
        _buildSummaryRow('Courier Charge', courierCharge),
        _buildSummaryRow('GST (18%)', gst),
        _buildSummaryRow('Advance Received', advanceReceived),
        const Divider(),
        _buildSummaryRow('Total', total, isBold: true),
        _buildSummaryRow('Balance Due', balance,
            isBold: true, isNegative: double.parse(balance) > 0),
        const Divider(),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Information',
          style: Orderdetailstyles.titleHeaders,
        ),
        const SizedBox(height: 8),
        _buildSummaryRow(
            'Method', order?['courier'] == true ? 'Courier' : 'Pickup'),
        _buildSummaryRow('Tracking Number', 'Not Available'),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Orderdetailstyles.subTitles.copyWith(
              color: isNegative ? Colors.red : ColorPalatte.gray,
            ),
          ),
          Text(
            label == 'Total' ||
                    label == 'Subtotal' ||
                    label == 'Courier Charge' ||
                    label == 'GST (18%)' ||
                    label == 'Advance Received' ||
                    label == 'Balance Due'
                ? '₹$value'
                : value,
            style: Orderdetailstyles.subTitles.copyWith(
              color: isNegative ? Colors.red : ColorPalatte.black,
            ),
          ),
        ],
      ),
    );
  }

  // Build delivery status section with checkbox and date field
  Widget _buildDeliveryStatusSection(int? orderItemId, Map<String, dynamic>? item) {
    if (orderItemId == null || item == null) {
      return const SizedBox.shrink();
    }

    bool isDelivered = item['delivered'] == true;
    String? actualDeliveryDateStr = item['actualDeliveryDate'];
    DateTime? actualDeliveryDate;
    
    if (actualDeliveryDateStr != null && actualDeliveryDateStr.isNotEmpty) {
      try {
        actualDeliveryDate = DateTime.parse(actualDeliveryDateStr);
      } catch (e) {
        print('Error parsing actualDeliveryDate: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isDelivered,
                onChanged: (bool? value) async {
                  if (value != null) {
                    await _updateDeliveryStatus(orderItemId, value, actualDeliveryDate);
                  }
                },
                activeColor: ColorPalatte.primary,
              ),
              const Text(
                'Delivered',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'Actual Delivery Date: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: actualDeliveryDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      await _updateDeliveryStatus(orderItemId, isDelivered, picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      actualDeliveryDate != null
                          ? DateFormat('MMM dd, yyyy').format(actualDeliveryDate)
                          : 'Select Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: actualDeliveryDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateDeliveryStatus(int orderItemId, bool delivered, DateTime? actualDeliveryDate) async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      CustomSnackbar.showSnackbar(context, "Shop ID is missing", duration: const Duration(seconds: 2));
      return;
    }

    try {
      final payload = {
        'delivered': delivered,
        'actualDeliveryDate': actualDeliveryDate != null
            ? DateFormat('yyyy-MM-dd').format(actualDeliveryDate)
            : null,
      };

      final response = await ApiService().patch(
        '${Urls.orders}/$shopId/item/$orderItemId/delivery',
        context,
        data: payload,
      );

      if (response.statusCode == 200) {
        // Update local state
        setState(() {
          final items = order?['items'] as List<dynamic>? ?? [];
          for (var i = 0; i < items.length; i++) {
            if (items[i]['orderItemId'] == orderItemId) {
              items[i]['delivered'] = delivered;
              items[i]['actualDeliveryDate'] = actualDeliveryDate != null
                  ? DateFormat('yyyy-MM-dd').format(actualDeliveryDate)
                  : null;
              break;
            }
          }
        });

        CustomSnackbar.showSnackbar(
          context,
          'Delivery status updated successfully',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      CustomSnackbar.showSnackbar(
        context,
        'Error updating delivery status: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Build media display for an order item
  Widget _buildItemMedia(List<Map<String, dynamic>> mediaList) {
    // Separate images and audio
    final images = mediaList.where((m) => m['mediaType'] == 'image').toList();
    final audioFiles = mediaList.where((m) => m['mediaType'] == 'audio').toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, size: 18, color: ColorPalatte.primary),
              const SizedBox(width: 8),
              Text(
                'Pictures (${images.length} ${images.length == 1 ? 'picture' : 'pictures'}${audioFiles.isNotEmpty ? ', ${audioFiles.length} ${audioFiles.length == 1 ? 'audio' : 'audio files'}' : ''})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalatte.primary,
                ),
              ),
            ],
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final media = images[index];
                final mediaUrl = media['mediaUrl']?.toString() ?? '';
                return GestureDetector(
                  onTap: () {
                    // Show full screen image
                    _showFullScreenImage(mediaUrl);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${Urls.baseUrl}$mediaUrl',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          if (audioFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...audioFiles.map((audio) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.audiotrack, color: ColorPalatte.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audio['fileName']?.toString() ?? 'Audio File',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (audio['fileSize'] != null)
                            Text(
                              '${(audio['fileSize'] / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.play_circle_outline, color: ColorPalatte.primary),
                      onPressed: () {
                        // TODO: Play audio
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Audio playback coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // Show full screen image
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  '${Urls.baseUrl}$imageUrl',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
