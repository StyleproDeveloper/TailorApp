import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Services/PDFService.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CommonStyles.dart';
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
  Map<String, dynamic>? shopInfo; // Shop information for PDF
  String? billingTerms; // Billing terms for PDF

  @override
  void initState() {
    super.initState();
    // Load permissions first
    GlobalVariables.loadShopId();
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

      print('🔍 Fetching media for ${items.length} order items');

      // Fetch media for each order item
      for (var item in items) {
        final orderItemId = item['orderItemId'];
        if (orderItemId != null) {
          try {
            final String requestUrl = "${Urls.orderMedia}/$shopId/$orderId/$orderItemId";
            print('🔍 Fetching media from: $requestUrl');
            final response = await ApiService().get(requestUrl, context);
            
            if (response.data != null && response.data['data'] != null) {
              final mediaList = response.data['data'] as List<dynamic>;
              final mediaListMap = mediaList.cast<Map<String, dynamic>>();
              mediaMap[orderItemId] = mediaListMap;
              
              // Debug: Log what media was found
              final images = mediaListMap.where((m) => m['mediaType'] == 'image').toList();
              final audioFiles = mediaListMap.where((m) => m['mediaType'] == 'audio').toList();
              print('✅ OrderItem $orderItemId: ${images.length} images, ${audioFiles.length} audio files');
              if (audioFiles.isNotEmpty) {
                print('   🎵 Audio files: ${audioFiles.map((a) => a['fileName'] ?? 'unknown').join(', ')}');
              }
            } else {
              print('⚠️ No media data returned for orderItemId $orderItemId');
            }
          } catch (e) {
            print('❌ Error fetching media for orderItemId $orderItemId: $e');
            // Continue with other items even if one fails
          }
        }
      }

      print('🔍 Total media fetched: ${mediaMap.length} order items have media');
      if (mounted) {
        setState(() {
          orderItemMedia = mediaMap;
        });
      }
    } catch (e) {
      print('❌ Error fetching order item media: $e');
    }
  }

  Future<void> fetchProductDetail() async {
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
          // Fetch shop information for PDF
          _fetchShopInfo();
          // Fetch billing terms for PDF
          _fetchBillingTerms();
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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: ColorPalatte.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showPrintMenu(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.print,
                      color: ColorPalatte.primary,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
            const Text('Order Details', style: Commonstyles.headerText),
          ],
        ),
        backgroundColor: ColorPalatte.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: ColorPalatte.black,
            size: 19,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: ColorPalatte.borderGray,
            height: 0.5,
          ),
        ),
        actions: [
          // Only show edit button if user has editOrder permission
          if (GlobalVariables.hasPermission('editOrder'))
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
    final advanceReceivedDateStr = order?['advanceReceivedDate']?.toString() ?? '';
    final advanceReceivedDate = advanceReceivedDateStr.trim().isNotEmpty
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(advanceReceivedDateStr))
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
        
        // Debug logging
        if (orderItemId != null) {
          print('🔍 Building item #${index + 1} with orderItemId: $orderItemId');
          print('   - itemMedia: ${itemMedia != null ? itemMedia.length : 'null'} items');
          if (itemMedia != null && itemMedia.isNotEmpty) {
            final images = itemMedia.where((m) => m['mediaType'] == 'image').toList();
            final audioFiles = itemMedia.where((m) => m['mediaType'] == 'audio').toList();
            print('   - Images: ${images.length}, Audio: ${audioFiles.length}');
          }
        }
        
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
    // If user doesn't have viewPrice permission, don't show additional costs
    if (!GlobalVariables.hasPermission('viewPrice')) {
      return [];
    }
    
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
                // Only show amount if user has viewPrice permission
                if (GlobalVariables.hasPermission('viewPrice'))
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
        // Highlighted header section
        tilePadding: EdgeInsets.zero,
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorPalatte.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        title.split(' - ')[0], // Extract "Item #1" part
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Orderdetailstyles.titleHeadersSide,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Only show cost if user has viewPrice permission
              if (GlobalVariables.hasPermission('viewPrice'))
                Text(
                  '₹$cost',
                  style: Orderdetailstyles.subTitles,
                ),
            ],
          ),
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
        tilePadding: EdgeInsets.zero,
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorPalatte.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '₹$cost',
                style: Orderdetailstyles.subTitles,
              ),
            ],
          ),
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
    // If user doesn't have viewPrice permission, don't show cost summary
    if (!GlobalVariables.hasPermission('viewPrice')) {
      return const SizedBox.shrink();
    }
    
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
    
    // Apply discount to subtotal
    final discountAmount = (order?['discount'] ?? 0).toDouble();
    final subtotalAfterDiscount = (subtotalValue - discountAmount).clamp(0.0, double.infinity);
    
    final subtotal = subtotalValue.toStringAsFixed(0);
    final discount = discountAmount.toStringAsFixed(0);
    final subtotalAfterDiscountStr = subtotalAfterDiscount.toStringAsFixed(0);
    final courierCharge = order?['courierCharge']?.toString() ?? '0';
    
    // Calculate GST on discounted subtotal (18%)
    final gst = order?['gst'] == true
        ? (subtotalAfterDiscount * 0.18).toStringAsFixed(0)
        : '0';
    final advanceReceived = order?['advancereceived']?.toString() ?? '0';
    final paidAmount = (order?['paidAmount'] ?? 0).toDouble();
    
    // Final total: discounted subtotal + courier + GST
    final total = (subtotalAfterDiscount +
            double.parse(courierCharge) +
            double.parse(gst))
        .toStringAsFixed(0);
    // Balance = Total - Total Paid (which includes advance + all payments)
    final balance = (double.parse(total) - paidAmount)
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
        if (discountAmount > 0) ...[
          _buildSummaryRow('Discount', '-$discount', isNegative: true),
          _buildSummaryRow('Subtotal After Discount', subtotalAfterDiscountStr),
        ],
        _buildSummaryRow('Courier Charge', courierCharge),
        _buildSummaryRow('GST (18%)', gst),
        const Divider(),
        _buildSummaryRow('Total', total, isBold: true),
        _buildSummaryRow('Total Paid', paidAmount.toStringAsFixed(0), isBold: true),
        _buildSummaryRow('Balance Due', balance,
            isBold: true, isNegative: double.parse(balance) > 0),
        // Only show payment buttons if user has viewPrice permission
        if (GlobalVariables.hasPermission('viewPrice')) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalatte.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text('Add Payment'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentHistoryDialog(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalatte.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: ColorPalatte.primary),
                  ),
                  icon: const Icon(Icons.history, size: 20),
                  label: const Text('Payment History'),
                ),
              ),
            ],
          ),
        ],
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
    
    // Debug logging
    print('🔍 _buildItemMedia called with ${mediaList.length} total media items');
    print('   - Images: ${images.length}');
    print('   - Audio: ${audioFiles.length}');
    if (audioFiles.isNotEmpty) {
      print('   - Audio files: ${audioFiles.map((a) => a['fileName'] ?? 'unknown').join(', ')}');
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
                // Check if URL is already a full URL (S3 URLs start with https://)
                final imageUrl = mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')
                    ? mediaUrl
                    : '${Urls.baseUrl}$mediaUrl';
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
                        imageUrl,
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
            Text(
              'Audio Recordings:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: audioFiles.length,
              itemBuilder: (context, index) {
                final audio = audioFiles[index];
                final mediaUrl = audio['mediaUrl']?.toString() ?? '';
                final fileName = audio['fileName']?.toString() ?? 'Audio Recording';
                final fileSize = audio['fileSize'] != null ? (audio['fileSize'] / 1024).toStringAsFixed(1) : '0';
                final duration = audio['duration'] != null ? (audio['duration'] as num).toDouble() : 0.0;
                
                // Check if URL is already a full URL (S3 URLs start with https://)
                final audioUrl = mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')
                    ? mediaUrl
                    : '${Urls.baseUrl}$mediaUrl';
                
                // Format duration
                String durationText = '';
                if (duration > 0) {
                  final minutes = (duration / 60).floor();
                  final seconds = (duration % 60).floor();
                  durationText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.audiotrack,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        if (durationText.isNotEmpty) ...[
                          Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            durationText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.storage, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '$fileSize KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.play_circle_filled,
                        color: ColorPalatte.primary,
                        size: 36,
                      ),
                      onPressed: () => _playAudio(audioUrl),
                      tooltip: 'Play audio',
                    ),
                    onTap: () => _playAudio(audioUrl),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // Play audio file
  void _playAudio(String audioUrl) {
    showDialog(
      context: context,
      builder: (context) => _AudioPlayerDialog(audioUrl: audioUrl),
    );
  }

  // Show full screen image
  void _showFullScreenImage(String imageUrl) {
    // Check if URL is already a full URL (S3 URLs start with https://)
    final fullImageUrl = imageUrl.startsWith('http://') || imageUrl.startsWith('https://')
        ? imageUrl
        : '${Urls.baseUrl}$imageUrl';
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
                  fullImageUrl,
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

  // Fetch shop information for PDF
  Future<void> _fetchShopInfo() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final response = await ApiService().get('${Urls.shopName}/$shopId', context);
      
      if (response.data != null) {
        final responseData = response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
        final shopDataFromResponse = responseData['data'] ?? responseData;
        
        if (mounted) {
          setState(() {
            shopInfo = shopDataFromResponse is Map ? shopDataFromResponse as Map<String, dynamic> : null;
          });
        }
      }
    } catch (e) {
      print('Error fetching shop info: $e');
      // Don't show error to user, PDF generation will use defaults
    }
  }

  // Fetch billing terms for PDF
  Future<void> _fetchBillingTerms() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final response = await ApiService().get('${Urls.billingTerm}/$shopId?pageNumber=1&pageSize=1', context);
      
      if (response.data != null && response.data['data'] != null) {
        final billingTermsList = response.data['data'] as List<dynamic>?;
        if (billingTermsList != null && billingTermsList.isNotEmpty) {
          final billingTerm = billingTermsList[0] as Map<String, dynamic>;
          final terms = billingTerm['terms']?.toString();
          
          if (mounted && terms != null && terms.isNotEmpty) {
            setState(() {
              billingTerms = terms;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching billing terms: $e');
      // Don't show error to user, PDF generation will work without terms
    }
  }

  // Generate PDF invoice
  Future<void> _generatePDF() async {
    if (order == null) {
      CustomSnackbar.showSnackbar(
        context,
        'Order data not available',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // If shop info not loaded, try to fetch it
    if (shopInfo == null) {
      showLoader(context);
      await _fetchShopInfo();
      hideLoader(context);
    }

    // If billing terms not loaded, try to fetch them
    if (billingTerms == null || billingTerms!.isEmpty) {
      await _fetchBillingTerms();
    }

    // Fetch payment history for PDF
    List<dynamic> paymentHistory = [];
    try {
      paymentHistory = await _fetchPaymentHistory();
    } catch (e) {
      print('Error fetching payment history for PDF: $e');
      // Continue without payment history if fetch fails
    }

    // Use default shop info if not available
    final shopData = shopInfo ?? {
      'shopName': 'Style Pros',
      'yourName': '',
      'mobile': '',
      'email': '',
      'addressLine1': '',
      'street': '',
      'city': '',
      'state': '',
      'postalCode': '',
    };

    try {
      await PDFService.generateOrderInvoice(
        order: order!,
        shopInfo: shopData,
        dressTypeNames: dressTypeNames,
        billingTerms: billingTerms,
        paymentHistory: paymentHistory.isNotEmpty ? paymentHistory : null,
      );
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Error generating PDF: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // Show Add Payment Dialog
  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String selectedPaymentType = 'partial';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    hintText: 'Enter payment amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        dateController.text = DateFormat('yyyy-MM-dd').format(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentType,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'advance', child: Text('Advance')),
                    DropdownMenuItem(value: 'partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'final', child: Text('Final')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentType = value ?? 'partial';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any notes about this payment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter payment amount')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                await _addPayment(
                  amount,
                  dateController.text,
                  selectedPaymentType,
                  notesController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // Add Payment
  Future<void> _addPayment(
    double amount,
    String paymentDate,
    String paymentType,
    String notes,
  ) async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null || orderId == null) return;

    showLoader(context);
    try {
      final userId = GlobalVariables.userId?.toString() ?? '';
      final payload = {
        'orderId': orderId,
        'paidAmount': amount,
        'paymentDate': paymentDate,
        'paymentType': paymentType,
        'notes': notes,
        'owner': userId,
      };

      final response = await ApiService().post(
        '${Urls.payments}/$shopId',
        data: payload,
        context,
      );

      hideLoader(context);

      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          // Refresh order data first, then show success message
          await fetchProductDetail();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data?['message'] ?? 'Failed to add payment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      hideLoader(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show Edit Payment Dialog
  void _showEditPaymentDialog(Map<String, dynamic> payment) {
    // Check if user has viewPrice permission
    if (!GlobalVariables.hasPermission('viewPrice')) {
      CustomSnackbar.showSnackbar(
        context,
        'You do not have permission to view or edit payments',
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    final amountController = TextEditingController(
      text: (payment['paidAmount'] ?? 0).toString(),
    );
    final notesController = TextEditingController(
      text: payment['notes']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: payment['paymentDate']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String selectedPaymentType = payment['paymentType'] ?? 'partial';
    final paymentId = payment['paymentId'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    hintText: 'Enter payment amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateController.text.isNotEmpty
                          ? DateTime.tryParse(dateController.text) ?? DateTime.now()
                          : DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        dateController.text = DateFormat('yyyy-MM-dd').format(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPaymentType,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'advance', child: Text('Advance')),
                    DropdownMenuItem(value: 'partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'final', child: Text('Final')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentType = value ?? 'partial';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any notes about this payment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter payment amount')),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                await _updatePayment(
                  paymentId,
                  amount,
                  dateController.text,
                  selectedPaymentType,
                  notesController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Update Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // Update Payment
  Future<void> _updatePayment(
    int? paymentId,
    double amount,
    String paymentDate,
    String paymentType,
    String notes,
  ) async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null || paymentId == null) return;

    showLoader(context);
    try {
      final payload = {
        'paidAmount': amount,
        'paymentDate': paymentDate,
        'paymentType': paymentType,
        'notes': notes,
      };

      final response = await ApiService().patch(
        '${Urls.payments}/$shopId/$paymentId',
        data: payload,
        context,
      );

      hideLoader(context);

      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          // Refresh order data first, then show success message
          await fetchProductDetail();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data?['message'] ?? 'Failed to update payment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      hideLoader(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show Payment History Dialog
  void _showPaymentHistoryDialog() {
    // Check if user has viewPrice permission
    if (!GlobalVariables.hasPermission('viewPrice')) {
      CustomSnackbar.showSnackbar(
        context,
        'You do not have permission to view payment history',
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null || orderId == null) return;

    showDialog(
      context: context,
      builder: (context) => FutureBuilder(
        future: _fetchPaymentHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Payment History'),
              content: Text('Error loading payment history: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final payments = snapshot.data as List<dynamic>? ?? [];
          final advanceReceived = (order?['advancereceived'] ?? 0).toDouble();
          final advanceReceivedDate = order?['advanceReceivedDate']?.toString() ?? '';

          return AlertDialog(
            title: const Text('Payment History'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (advanceReceived > 0) ...[
                      _buildPaymentHistoryRow({
                        'type': 'advance',
                        'paymentType': 'advance',
                        'paidAmount': advanceReceived,
                        'paymentDate': advanceReceivedDate,
                      }),
                      const Divider(),
                    ],
                    if (payments.isEmpty && advanceReceived == 0)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No payments recorded'),
                      )
                    else
                      ...payments.map((payment) => _buildPaymentHistoryRow(
                            payment, // Pass full payment object
                          )),
                    // Only show total paid if user has viewPrice permission
                    if (GlobalVariables.hasPermission('viewPrice')) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Paid:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '₹${((order?['paidAmount'] ?? 0).toDouble()).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Fetch Payment History
  Future<List<dynamic>> _fetchPaymentHistory() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null || orderId == null) return [];

    try {
      final response = await ApiService().get(
        '${Urls.payments}/$shopId/order/$orderId',
        context,
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // Build Payment History Row
  Widget _buildPaymentHistoryRow(Map<String, dynamic> payment) {
    final label = _getPaymentTypeLabel(payment['paymentType'] ?? 'partial');
    final amount = (payment['paidAmount'] ?? 0).toDouble();
    final date = payment['paymentDate']?.toString() ?? '';
    final notes = payment['notes']?.toString();
    final paymentId = payment['paymentId'];
    final isAdvance = payment['paymentType'] == 'advance' || payment['type'] == 'advance';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Row(
                children: [
                  // Only show amount if user has viewPrice permission
                  if (GlobalVariables.hasPermission('viewPrice'))
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  // Show edit icon only for non-advance payments and if user has viewPrice permission
                  if (!isAdvance && paymentId != null && GlobalVariables.hasPermission('viewPrice')) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: ColorPalatte.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.pop(context); // Close payment history dialog
                        _showEditPaymentDialog(payment);
                      },
                      tooltip: 'Edit payment',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.note, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notes,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Get Payment Type Label
  String _getPaymentTypeLabel(String type) {
    switch (type) {
      case 'advance':
        return 'Advance Payment';
      case 'partial':
        return 'Partial Payment';
      case 'final':
        return 'Final Payment';
      case 'other':
        return 'Other Payment';
      default:
        return 'Payment';
    }
  }

  // Show print menu
  void _showPrintMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.receipt, color: ColorPalatte.primary),
                title: Text('Print Invoice'),
                subtitle: Text('Print complete order invoice with payments'),
                onTap: () {
                  Navigator.pop(context);
                  _generatePDF();
                },
              ),
              ListTile(
                leading: Icon(Icons.description, color: ColorPalatte.primary),
                title: Text('Print Order Details'),
                subtitle: Text('Print customer, dress type, pattern & measurements'),
                onTap: () {
                  Navigator.pop(context);
                  _printOrderDetails();
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Print order details (customer, dress type, pattern, measurements)
  Future<void> _printOrderDetails() async {
    try {
      if (order == null) {
        CustomSnackbar.showSnackbar(
          context,
          'Order data not available',
          duration: Duration(seconds: 2),
        );
        return;
      }

      showLoader(context);

      // Fetch all images first
      final items = order!['items'] as List<dynamic>? ?? [];
      Map<int, List<pw.MemoryImage>> itemImages = {};
      
      for (var item in items) {
        final orderItemId = item['orderItemId'];
        if (orderItemId != null) {
          final media = orderItemMedia[orderItemId];
          if (media != null) {
            final images = media.where((m) => m['mediaType'] == 'image').toList();
            List<pw.MemoryImage> pdfImages = [];
            
            for (var imageMedia in images) {
              try {
                final mediaUrl = imageMedia['mediaUrl']?.toString() ?? '';
                if (mediaUrl.isNotEmpty) {
                  final imageUrl = mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')
                      ? mediaUrl
                      : '${Urls.baseUrl}$mediaUrl';
                  
                  final response = await http.get(Uri.parse(imageUrl));
                  if (response.statusCode == 200) {
                    pdfImages.add(pw.MemoryImage(response.bodyBytes));
                  }
                }
              } catch (e) {
                print('Error loading image for PDF: $e');
              }
            }
            
            if (pdfImages.isNotEmpty) {
              itemImages[orderItemId] = pdfImages;
            }
          }
        }
      }

      hideLoader(context);

      // Validate we have items to print
      if (items.isEmpty) {
        CustomSnackbar.showSnackbar(
          context,
          'No order items to print',
          duration: Duration(seconds: 2),
        );
        return;
      }

      print('📄 Creating PDF with ${items.length} items...');

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            try {
              return [
                // Header
                pw.Text(
                  'Order Details',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Customer Details Section
                pw.Text(
                  'Customer Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildCustomerDetailsSectionPDF(),
                pw.SizedBox(height: 20),

                // Order Items Section
                pw.Text(
                  'Order Items',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value as Map<String, dynamic>;
                  final orderItemId = item['orderItemId'];
                  final images = orderItemId != null ? itemImages[orderItemId] : null;
                  return _buildOrderItemSectionPDF(item, index + 1, images);
                }).toList(),
              ];
            } catch (e) {
              print('❌ Error building PDF content: $e');
              return [
                pw.Text(
                  'Error generating PDF content: $e',
                  style: pw.TextStyle(color: PdfColors.red),
                ),
              ];
            }
          },
        ),
      );

      // Print or share PDF
      print('📄 Generating PDF for printing...');
      final pdfBytes = await pdf.save();
      print('✅ PDF generated successfully, size: ${pdfBytes.length} bytes');
      
      if (pdfBytes.isEmpty) {
        throw Exception('PDF generation failed: empty PDF bytes');
      }
      
      try {
        if (kIsWeb) {
          // On web, use sharePdf which works better
          print('🌐 Web platform detected, using sharePdf...');
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: 'order_details_${orderId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          print('✅ PDF shared successfully on web');
        } else {
          // On mobile, try print dialog first
          print('📱 Mobile platform detected, using layoutPdf...');
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
          );
          print('✅ Print dialog opened successfully');
        }
      } catch (printError) {
        print('⚠️ Print/share failed, trying alternative: $printError');
        // Fallback: try the other method
        try {
          if (kIsWeb) {
            // If share failed on web, try layoutPdf
            await Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => pdfBytes,
            );
          } else {
            // If print failed on mobile, try share
            await Printing.sharePdf(
              bytes: pdfBytes,
              filename: 'order_details_${orderId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
          }
          print('✅ Alternative method succeeded');
        } catch (shareError) {
          print('❌ Both print and share failed: $shareError');
          throw Exception('Failed to print or share PDF: $shareError');
        }
      }
    } catch (e, stackTrace) {
      hideLoader(context);
      print('❌ Error printing order details: $e');
      print('❌ Stack trace: $stackTrace');
      CustomSnackbar.showSnackbar(
        context,
        'Failed to print order details: ${e.toString()}',
        duration: Duration(seconds: 3),
      );
    }
  }

  // Build customer details section for PDF
  pw.Widget _buildCustomerDetailsSectionPDF() {
    final customerName = order?['customer_name']?.toString() ?? 'N/A';
    final customerMobile = order?['customer_mobile']?.toString();
    final customerId = order?['customerId']?.toString();
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRowPDF('Name:', customerName),
          if (customerMobile != null && customerMobile.isNotEmpty)
            _buildInfoRowPDF('Mobile:', customerMobile),
          if (customerId != null)
            _buildInfoRowPDF('Customer ID:', customerId),
        ],
      ),
    );
  }

  // Build order item section for PDF (dress type, pattern, measurements, images)
  pw.Widget _buildOrderItemSectionPDF(
    Map<String, dynamic> item,
    int itemNumber,
    List<pw.MemoryImage>? images,
  ) {
    final dressTypeId = item['dressTypeId'];
    final dressTypeName = dressTypeNames[dressTypeId] ?? 'Dress Type $dressTypeId';
    final measurementList = item['measurement'] as List<dynamic>? ?? [];
    final measurement = measurementList.isNotEmpty
        ? measurementList[0] as Map<String, dynamic>
        : <String, dynamic>{};
    
    // Get patterns - check both 'pattern' and 'Pattern' keys, and handle nested structure
    List<dynamic> patternList = [];
    print('🔍 Extracting patterns for item $itemNumber');
    print('🔍 Item keys: ${item.keys.toList()}');
    
    if (item['Pattern'] != null) {
      // Backend returns Pattern with capital P, which is an array of pattern objects
      final patternData = item['Pattern'];
      print('🔍 Found Pattern (capital P): $patternData');
      print('🔍 Pattern data type: ${patternData.runtimeType}');
      
      if (patternData is List && patternData.isNotEmpty) {
        // Check if it's a list of pattern objects with 'patterns' array inside
        final firstPattern = patternData[0];
        print('🔍 First pattern object: $firstPattern');
        
        if (firstPattern is Map && firstPattern['patterns'] != null) {
          // Extract the patterns array from the pattern object
          patternList = firstPattern['patterns'] as List<dynamic>? ?? [];
          print('🔍 Extracted patterns from nested structure: ${patternList.length} patterns');
        } else if (firstPattern is Map && firstPattern['category'] != null) {
          // Direct list of pattern objects
          patternList = patternData;
          print('🔍 Using direct pattern list: ${patternList.length} patterns');
        }
      }
    } else if (item['pattern'] != null) {
      // Fallback to lowercase 'pattern'
      final patternData = item['pattern'];
      print('🔍 Found pattern (lowercase): $patternData');
      
      if (patternData is List) {
        patternList = patternData;
        print('🔍 Using lowercase pattern list: ${patternList.length} patterns');
      } else if (patternData is Map && patternData['patterns'] != null) {
        patternList = patternData['patterns'] as List<dynamic>? ?? [];
        print('🔍 Extracted from lowercase pattern patterns array: ${patternList.length} patterns');
      }
    } else {
      print('⚠️ No pattern data found in item');
    }
    
    print('🔍 Final pattern list: $patternList');
    
    final specialInstructions = item['special_instructions']?.toString() ?? '';
    final deliveryDate = item['delivery_date']?.toString() ?? '';

    // Build image widgets from pre-loaded images
    List<pw.Widget> imageWidgets = [];
    if (images != null && images.isNotEmpty) {
      for (var pdfImage in images) {
        imageWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8, right: 8),
            child: pw.Image(
              pdfImage,
              fit: pw.BoxFit.cover,
              width: 100,
              height: 100,
            ),
          ),
        );
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Item Number
          pw.Text(
            'Item #$itemNumber',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.SizedBox(height: 10),

          // Dress Type
          pw.Text(
            'Dress Type:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            dressTypeName,
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 10),

          // Dress Pattern
          pw.Text(
            'Pattern:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          if (patternList.isNotEmpty) ...[
            ...patternList.where((pattern) => pattern is Map<String, dynamic>).map((pattern) {
              final category = pattern['category']?.toString() ?? 'Unknown';
              final names = pattern['name'];
              String patternNames = '';
              if (names is List) {
                patternNames = names.where((n) => n != null).join(', ');
              } else if (names != null) {
                patternNames = names.toString();
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  patternNames.isNotEmpty ? '$category: $patternNames' : category,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              );
            }).toList(),
          ] else ...[
            pw.Text(
              'No pattern selected',
              style: pw.TextStyle(
                fontSize: 11,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          ],
          pw.SizedBox(height: 10),

          // Images
          if (imageWidgets.isNotEmpty) ...[
            pw.Text(
              'Images:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: imageWidgets,
            ),
            pw.SizedBox(height: 10),
          ],

          // Measurements
          if (measurement.isNotEmpty) ...[
            pw.Text(
              'Measurements:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCellPDF('Measurement', isHeader: true),
                    _buildTableCellPDF('Value', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Measurement rows
                ...measurement.entries
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
                    .map((entry) {
                  final key = _beautifyKey(entry.key);
                  final value = entry.value?.toString() ?? '';
                  return pw.TableRow(
                    children: [
                      _buildTableCellPDF(key),
                      _buildTableCellPDF(value, align: pw.TextAlign.right),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // Special Instructions
          if (specialInstructions.isNotEmpty) ...[
            pw.Text(
              'Special Instructions:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              specialInstructions,
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 10),
          ],

          // Delivery Date
          if (deliveryDate.isNotEmpty) ...[
            pw.Text(
              'Delivery Date:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              deliveryDate,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to build info row for PDF
  pw.Widget _buildInfoRowPDF(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build table cell for PDF
  pw.Widget _buildTableCellPDF(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}

// Audio Player Dialog Widget
class _AudioPlayerDialog extends StatefulWidget {
  final String audioUrl;

  const _AudioPlayerDialog({required this.audioUrl});

  @override
  State<_AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<_AudioPlayerDialog> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
    _preloadAudio();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      print('🎵 AudioPlayer state changed: $state');
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          // Set loading to false when playing starts
          if (state == PlayerState.playing) {
            _isLoading = false;
          }
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      print('🎵 AudioPlayer duration: ${duration.inSeconds}s');
      if (mounted) {
        setState(() {
          _duration = duration;
          // Once duration is loaded, we're no longer loading
          if (duration.inSeconds > 0) {
            _isLoading = false;
          }
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to errors
    _audioPlayer.onLog.listen((log) {
      print('🎵 AudioPlayer log: $log');
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      print('🎵 AudioPlayer completed');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _preloadAudio() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Ensure URL is full URL
      final fullUrl = widget.audioUrl.startsWith('http://') || widget.audioUrl.startsWith('https://')
          ? widget.audioUrl
          : '${Urls.baseUrl}${widget.audioUrl}';
      
      print('🎵 Preloading audio from: $fullUrl');
      
      // Preload the audio source
      await _audioPlayer.setSource(UrlSource(fullUrl));
      
      print('🎵 Audio preloaded successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error preloading audio: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        String errorMessage = 'Failed to load audio: ${e.toString()}';
        
        // Check if it's a CORS or format error
        if (e.toString().contains('CORS') || 
            e.toString().contains('Format error') ||
            e.toString().contains('MEDIA_ELEMENT_ERROR')) {
          errorMessage = 'Audio playback failed. This may be due to:\n'
              '1. CORS configuration on S3 bucket\n'
              '2. Audio format not supported by browser\n'
              '3. Network connectivity issues\n\n'
              'Please check S3 bucket CORS settings or contact support.';
        }
        
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playPause() async {
    try {
      print('🎵 Play/Pause clicked. Current state: isPlaying=$_isPlaying, duration=${_duration.inSeconds}s');
      
      if (_isPlaying) {
        print('🎵 Pausing audio...');
        await _audioPlayer.pause();
      } else {
        print('🎵 Playing audio...');
        
        setState(() {
          _isLoading = true;
          _error = null;
        });
        
        // Ensure URL is full URL
        final fullUrl = widget.audioUrl.startsWith('http://') || widget.audioUrl.startsWith('https://')
            ? widget.audioUrl
            : '${Urls.baseUrl}${widget.audioUrl}';
        
        print('🎵 Loading audio from: $fullUrl');
        
        // If duration is zero, source might not be loaded, so set it and play
        // Otherwise, just resume from current position
        if (_duration == Duration.zero) {
          print('🎵 Source not loaded, setting source and playing...');
          await _audioPlayer.play(UrlSource(fullUrl));
        } else {
          print('🎵 Source already loaded, resuming...');
          await _audioPlayer.resume();
        }
        
        print('🎵 Audio play/resume called successfully');
      }
    } catch (e, stackTrace) {
      print('❌ Error playing audio: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Error playing audio: ${e.toString()}';
          _isLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        width: kIsWeb ? 400 : 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Audio Player',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    _audioPlayer.stop();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.audiotrack,
              size: 64,
              color: ColorPalatte.primary,
            ),
            const SizedBox(height: 20),
            // Show audio URL for debugging (can be removed later)
            Text(
              widget.audioUrl.length > 50 
                  ? '${widget.audioUrl.substring(0, 50)}...'
                  : widget.audioUrl,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _preloadAudio,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalatte.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              // Progress indicator
              if (_duration.inSeconds > 0) ...[
                Slider(
                  value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    _seek(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (!_isLoading && _duration == Duration.zero) ...[
                Text(
                  'Duration: Unknown',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],
              // Play/Pause button - always show if duration is loaded, or show loading indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading && _duration == Duration.zero)
                    Column(
                      children: [
                        CircularProgressIndicator(color: ColorPalatte.primary),
                        const SizedBox(height: 8),
                        Text(
                          'Loading audio...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: ColorPalatte.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorPalatte.primary,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        iconSize: 80,
                        padding: const EdgeInsets.all(8),
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: ColorPalatte.primary,
                          size: 80,
                        ),
                        onPressed: _playPause,
                        tooltip: _isPlaying ? 'Pause' : 'Play',
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
}
