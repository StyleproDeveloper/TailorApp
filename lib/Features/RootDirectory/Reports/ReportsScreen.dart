import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/GlobalVariables.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = true;
  Map<String, dynamic> metrics = {};
  Map<String, dynamic> paymentMetrics = {};
  Map<String, dynamic> outstandingMetrics = {};
  List<Map<String, dynamic>> ordersByStatus = [];
  List<Map<String, dynamic>> topDressTypes = [];
  List<Map<String, dynamic>> monthlySales = [];

  @override
  void initState() {
    super.initState();
    _fetchReportsData();
  }

  Future<void> _fetchReportsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _fetchMetrics(),
        _fetchPaymentMetrics(),
        _fetchOutstandingMetrics(),
        _fetchOrdersByStatus(),
        _fetchTopDressTypes(),
        _fetchMonthlySales(),
      ]);
    } catch (e) {
      print('Error fetching reports data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMetrics() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final now = DateTime.now();
      
      // Today's date range
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      // This week's date range (Monday to Sunday)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekEndDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
      
      // This month's date range
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      // Last month's date range (for growth calculation)
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      // Fetch all orders and filter by date in the frontend for accuracy
      final allOrdersUrl = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=10000";
      final allOrdersResponse = await ApiService().get(allOrdersUrl, context);

      double todaySales = 0;
      double thisWeekSales = 0;
      double thisMonthSales = 0;
      double lastMonthSales = 0;
      int todayOrders = 0;
      int thisWeekOrders = 0;
      int thisMonthOrders = 0;
      int lastMonthOrders = 0;

      if (allOrdersResponse.data != null && allOrdersResponse.data['data'] != null) {
        final allOrders = allOrdersResponse.data['data'] as List<dynamic>;
        
        for (var order in allOrders) {
          final createdAt = order['createdAt'];
          if (createdAt == null) continue;
          
          DateTime orderDate;
          try {
            orderDate = DateTime.parse(createdAt);
          } catch (e) {
            continue;
          }
          
          final orderDateOnly = DateTime(orderDate.year, orderDate.month, orderDate.day);
          final todayDateOnly = DateTime(now.year, now.month, now.day);
          final estimationCost = (order['estimationCost'] ?? 0).toDouble();
          
          // Today's sales
          if (orderDateOnly.year == todayDateOnly.year && 
              orderDateOnly.month == todayDateOnly.month && 
              orderDateOnly.day == todayDateOnly.day) {
            todaySales += estimationCost;
            todayOrders++;
          }
          
          // This week's sales
          if (orderDate.isAfter(weekStartDate.subtract(const Duration(seconds: 1))) && 
              orderDate.isBefore(weekEndDate.add(const Duration(seconds: 1)))) {
            thisWeekSales += estimationCost;
            thisWeekOrders++;
          }
          
          // This month's sales
          if (orderDate.isAfter(currentMonthStart.subtract(const Duration(seconds: 1))) && 
              orderDate.isBefore(currentMonthEnd.add(const Duration(seconds: 1)))) {
            thisMonthSales += estimationCost;
            thisMonthOrders++;
          }
          
          // Last month's sales
          if (orderDate.isAfter(lastMonthStart.subtract(const Duration(seconds: 1))) && 
              orderDate.isBefore(lastMonthEnd.add(const Duration(seconds: 1)))) {
            lastMonthSales += estimationCost;
            lastMonthOrders++;
          }
        }
      }

      setState(() {
        metrics = {
          'todaySales': todaySales,
          'thisWeekSales': thisWeekSales,
          'thisMonthSales': thisMonthSales,
          'lastMonthSales': lastMonthSales,
          'todayOrders': todayOrders,
          'thisWeekOrders': thisWeekOrders,
          'thisMonthOrders': thisMonthOrders,
          'lastMonthOrders': lastMonthOrders,
          'salesGrowth': lastMonthSales > 0 ? ((thisMonthSales - lastMonthSales) / lastMonthSales * 100) : 0,
          'ordersGrowth': lastMonthOrders > 0 ? ((thisMonthOrders - lastMonthOrders) / lastMonthOrders * 100) : 0,
        };
      });
    } catch (e) {
      print('Error fetching metrics: $e');
    }
  }

  Future<void> _fetchOrdersByStatus() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final url = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=1000";
      final response = await ApiService().get(url, context);

      if (response.data != null && response.data['data'] != null) {
        final orders = response.data['data'] as List<dynamic>;
        Map<String, int> statusCounts = {};

        for (var order in orders) {
          final status = order['status'] ?? 'unknown';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }

        setState(() {
          ordersByStatus = statusCounts.entries.map((entry) => {
            'status': entry.key,
            'count': entry.value,
            'percentage': orders.isNotEmpty ? (entry.value / orders.length * 100) : 0,
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching orders by status: $e');
    }
  }

  Future<void> _fetchTopDressTypes() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final url = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=1000";
      final response = await ApiService().get(url, context);

      if (response.data != null && response.data['data'] != null) {
        final orders = response.data['data'] as List<dynamic>;
        Map<int, int> dressTypeCounts = {};

        for (var order in orders) {
          final items = order['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            final dressTypeId = item['dressTypeId'];
            if (dressTypeId != null) {
              dressTypeCounts[dressTypeId] = (dressTypeCounts[dressTypeId] ?? 0) + 1;
            }
          }
        }

        // Get dress type names
        final dressTypesUrl = "${Urls.addDress}/$shopId?pageNumber=1&pageSize=100";
        final dressTypesResponse = await ApiService().get(dressTypesUrl, context);
        Map<int, String> dressTypeNames = {};

        if (dressTypesResponse.data != null && dressTypesResponse.data['data'] != null) {
          final dressTypes = dressTypesResponse.data['data'] as List<dynamic>;
          for (var dressType in dressTypes) {
            dressTypeNames[dressType['dressTypeId']] = dressType['name'];
          }
        }

        setState(() {
          topDressTypes = dressTypeCounts.entries.map((entry) => {
            'dressTypeId': entry.key,
            'name': dressTypeNames[entry.key] ?? 'Dress Type ${entry.key}',
            'count': entry.value,
          }).toList()
            ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
        });
      }
    } catch (e) {
      print('Error fetching top dress types: $e');
    }
  }

  Future<void> _fetchMonthlySales() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final now = DateTime.now();
      List<Map<String, dynamic>> monthlyData = [];

      // Fetch all orders and filter by createdAt date
      final allOrdersUrl = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=10000";
      final allOrdersResponse = await ApiService().get(allOrdersUrl, context);

      if (allOrdersResponse.data != null && allOrdersResponse.data['data'] != null) {
        final allOrders = allOrdersResponse.data['data'] as List<dynamic>;

        // Get last 6 months
        for (int i = 5; i >= 0; i--) {
          final monthStart = DateTime(now.year, now.month - i, 1);
          final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

          double monthSales = 0;
          int monthOrders = 0;

          // Filter orders by createdAt date for this month
          for (var order in allOrders) {
            final createdAt = order['createdAt'];
            if (createdAt == null) continue;

            DateTime orderDate;
            try {
              orderDate = DateTime.parse(createdAt);
            } catch (e) {
              continue;
            }

            // Check if order was created in this month
            if (orderDate.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
                orderDate.isBefore(monthEnd.add(const Duration(seconds: 1)))) {
              monthOrders++;
              monthSales += (order['estimationCost'] ?? 0).toDouble();
            }
          }

          monthlyData.add({
            'month': DateFormat('MMM yyyy').format(monthStart),
            'sales': monthSales,
            'orders': monthOrders,
          });
        }
      }

      setState(() {
        monthlySales = monthlyData;
      });
    } catch (e) {
      print('Error fetching monthly sales: $e');
    }
  }

  Future<void> _fetchPaymentMetrics() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      final now = DateTime.now();

      // Today's date range
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // This week's date range (Monday to Sunday)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekEndDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

      // This month's date range
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Fetch all payments
      final allPaymentsUrl = "${Urls.payments}/$shopId?pageNumber=1&pageSize=10000";
      final allPaymentsResponse = await ApiService().get(allPaymentsUrl, context);

      double todayPayments = 0;
      double thisWeekPayments = 0;
      double thisMonthPayments = 0;

      if (allPaymentsResponse.data != null && allPaymentsResponse.data['data'] != null) {
        final allPayments = allPaymentsResponse.data['data'] as List<dynamic>;

        for (var payment in allPayments) {
          final paymentDate = payment['paymentDate'];
          if (paymentDate == null) continue;

          DateTime paymentDateTime;
          try {
            paymentDateTime = DateTime.parse(paymentDate);
          } catch (e) {
            continue;
          }

          final paidAmount = (payment['paidAmount'] ?? 0).toDouble();

          // Today's payments
          final paymentDateOnly = DateTime(paymentDateTime.year, paymentDateTime.month, paymentDateTime.day);
          final todayDateOnly = DateTime(now.year, now.month, now.day);
          if (paymentDateOnly.year == todayDateOnly.year &&
              paymentDateOnly.month == todayDateOnly.month &&
              paymentDateOnly.day == todayDateOnly.day) {
            todayPayments += paidAmount;
          }

          // This week's payments
          if (paymentDateTime.isAfter(weekStartDate.subtract(const Duration(seconds: 1))) &&
              paymentDateTime.isBefore(weekEndDate.add(const Duration(seconds: 1)))) {
            thisWeekPayments += paidAmount;
          }

          // This month's payments
          if (paymentDateTime.isAfter(currentMonthStart.subtract(const Duration(seconds: 1))) &&
              paymentDateTime.isBefore(currentMonthEnd.add(const Duration(seconds: 1)))) {
            thisMonthPayments += paidAmount;
          }
        }
      }

      setState(() {
        paymentMetrics = {
          'todayPayments': todayPayments,
          'thisWeekPayments': thisWeekPayments,
          'thisMonthPayments': thisMonthPayments,
        };
      });
    } catch (e) {
      print('Error fetching payment metrics: $e');
    }
  }

  Future<void> _fetchOutstandingMetrics() async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) return;

    try {
      // Fetch all orders
      final allOrdersUrl = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=10000";
      final allOrdersResponse = await ApiService().get(allOrdersUrl, context);

      double totalOrderValue = 0;
      double totalPaidAmount = 0;

      if (allOrdersResponse.data != null && allOrdersResponse.data['data'] != null) {
        final allOrders = allOrdersResponse.data['data'] as List<dynamic>;

        for (var order in allOrders) {
          // Calculate order total (subtotal + courier + GST - discount)
          final items = order['items'] as List<dynamic>? ?? [];
          double itemsTotal = 0;
          for (var item in items) {
            itemsTotal += (item['amount'] ?? 0).toDouble();
          }

          final additionalCosts = order['additionalCosts'] as List<dynamic>? ?? [];
          double additionalCostsTotal = 0;
          for (var cost in additionalCosts) {
            additionalCostsTotal += (cost['additionalCost'] ?? 0).toDouble();
          }

          double subtotal = itemsTotal + additionalCostsTotal;
          final discount = (order['discount'] ?? 0).toDouble();
          final subtotalAfterDiscount = (subtotal - discount).clamp(0.0, double.infinity);
          final courierCharge = (order['courierCharge'] ?? 0).toDouble();
          final gstAmount = order['gst'] == true ? (subtotalAfterDiscount * 0.18) : 0.0;
          final orderTotal = subtotalAfterDiscount + courierCharge + gstAmount;

          totalOrderValue += orderTotal;
          totalPaidAmount += (order['paidAmount'] ?? 0).toDouble();
        }
      }

      final outstandingAmount = totalOrderValue - totalPaidAmount;

      setState(() {
        outstandingMetrics = {
          'totalOrderValue': totalOrderValue,
          'totalPaidAmount': totalPaidAmount,
          'outstandingAmount': outstandingAmount,
        };
      });
    } catch (e) {
      print('Error fetching outstanding metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: ColorPalatte.white,
        appBar: Commonheader(title: 'Reports'),
        body: Center(child: CircularProgressIndicator(color: ColorPalatte.primary)),
      );
    }

    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(title: 'Reports'),
      body: RefreshIndicator(
        onRefresh: _fetchReportsData,
        color: ColorPalatte.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSalesMetrics(),
              const SizedBox(height: 20),
              _buildPaymentMetrics(),
              const SizedBox(height: 20),
              _buildOutstandingMetrics(),
              const SizedBox(height: 20),
              _buildOrdersByStatus(),
              const SizedBox(height: 20),
              _buildTopDressTypes(),
              const SizedBox(height: 20),
              _buildMonthlySalesChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalatte.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Today',
                '₹${NumberFormat('#,##0').format(metrics['todaySales'] ?? 0)}',
                '${metrics['todayOrders'] ?? 0} orders',
                Icons.today,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'This Week',
                '₹${NumberFormat('#,##0').format(metrics['thisWeekSales'] ?? 0)}',
                '${metrics['thisWeekOrders'] ?? 0} orders',
                Icons.date_range,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'This Month',
                '₹${NumberFormat('#,##0').format(metrics['thisMonthSales'] ?? 0)}',
                '${metrics['thisMonthOrders'] ?? 0} orders',
                Icons.calendar_month,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersByStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Orders by Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalatte.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            children: ordersByStatus.map((status) {
              final statusName = status['status'].toString().toUpperCase();
              final count = status['count'] as int;
              final percentage = status['percentage'] as double;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorPalatte.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopDressTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Dress Types',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalatte.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            children: topDressTypes.take(5).map((dressType) {
              final name = dressType['name'] as String;
              final count = dressType['count'] as int;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$count orders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ColorPalatte.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySalesChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Sales Trend',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalatte.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            children: monthlySales.map((month) {
              final monthName = month['month'] as String;
              final sales = month['sales'] as double;
              final orders = month['orders'] as int;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${NumberFormat('#,##0').format(sales)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorPalatte.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($orders orders)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Received',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalatte.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Today',
                '₹${NumberFormat('#,##0').format(paymentMetrics['todayPayments'] ?? 0)}',
                'Payments received',
                Icons.payment,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'This Week',
                '₹${NumberFormat('#,##0').format(paymentMetrics['thisWeekPayments'] ?? 0)}',
                'Payments received',
                Icons.date_range,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'This Month',
                '₹${NumberFormat('#,##0').format(paymentMetrics['thisMonthPayments'] ?? 0)}',
                'Payments received',
                Icons.calendar_month,
                Colors.blueGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutstandingMetrics() {
    final totalOrderValue = outstandingMetrics['totalOrderValue'] ?? 0.0;
    final totalPaidAmount = outstandingMetrics['totalPaidAmount'] ?? 0.0;
    final outstandingAmount = outstandingMetrics['outstandingAmount'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outstanding Payments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalatte.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              _buildOutstandingRow(
                'Total Order Value',
                totalOrderValue,
                Colors.blue,
              ),
              const Divider(),
              _buildOutstandingRow(
                'Total Paid Amount',
                totalPaidAmount,
                Colors.green,
              ),
              const Divider(),
              _buildOutstandingRow(
                'Outstanding Amount',
                outstandingAmount,
                outstandingAmount > 0 ? Colors.red : Colors.green,
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingRow(String label, double amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            '₹${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
