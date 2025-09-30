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
      // Get current month and last month dates
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);

      // Fetch orders for current month
      final currentMonthUrl = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=1000&startDate=${DateFormat('yyyy-MM-dd').format(currentMonthStart)}&endDate=${DateFormat('yyyy-MM-dd').format(now)}";
      final currentMonthResponse = await ApiService().get(currentMonthUrl, context);

      // Fetch orders for last month
      final lastMonthUrl = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=1000&startDate=${DateFormat('yyyy-MM-dd').format(lastMonthStart)}&endDate=${DateFormat('yyyy-MM-dd').format(lastMonthEnd)}";
      final lastMonthResponse = await ApiService().get(lastMonthUrl, context);

      double currentMonthSales = 0;
      double lastMonthSales = 0;
      int currentMonthOrders = 0;
      int lastMonthOrders = 0;

      if (currentMonthResponse.data != null && currentMonthResponse.data['data'] != null) {
        final currentOrders = currentMonthResponse.data['data'] as List<dynamic>;
        currentMonthOrders = currentOrders.length;
        currentMonthSales = currentOrders.fold(0.0, (sum, order) => sum + (order['estimationCost'] ?? 0.0));
      }

      if (lastMonthResponse.data != null && lastMonthResponse.data['data'] != null) {
        final lastOrders = lastMonthResponse.data['data'] as List<dynamic>;
        lastMonthOrders = lastOrders.length;
        lastMonthSales = lastOrders.fold(0.0, (sum, order) => sum + (order['estimationCost'] ?? 0.0));
      }

      setState(() {
        metrics = {
          'currentMonthSales': currentMonthSales,
          'lastMonthSales': lastMonthSales,
          'currentMonthOrders': currentMonthOrders,
          'lastMonthOrders': lastMonthOrders,
          'salesGrowth': lastMonthSales > 0 ? ((currentMonthSales - lastMonthSales) / lastMonthSales * 100) : 0,
          'ordersGrowth': lastMonthOrders > 0 ? ((currentMonthOrders - lastMonthOrders) / lastMonthOrders * 100) : 0,
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

      // Get last 6 months
      for (int i = 5; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        
        final url = "${Urls.ordersSave}/$shopId?pageNumber=1&pageSize=1000&startDate=${DateFormat('yyyy-MM-dd').format(monthStart)}&endDate=${DateFormat('yyyy-MM-dd').format(monthEnd)}";
        final response = await ApiService().get(url, context);

        double monthSales = 0;
        int monthOrders = 0;

        if (response.data != null && response.data['data'] != null) {
          final orders = response.data['data'] as List<dynamic>;
          monthOrders = orders.length;
          monthSales = orders.fold(0.0, (sum, order) => sum + (order['estimationCost'] ?? 0.0));
        }

        monthlyData.add({
          'month': DateFormat('MMM yyyy').format(monthStart),
          'sales': monthSales,
          'orders': monthOrders,
        });
      }

      setState(() {
        monthlySales = monthlyData;
      });
    } catch (e) {
      print('Error fetching monthly sales: $e');
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
                'This Month',
                '₹${NumberFormat('#,##0').format(metrics['currentMonthSales'] ?? 0)}',
                '${metrics['currentMonthOrders'] ?? 0} orders',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Last Month',
                '₹${NumberFormat('#,##0').format(metrics['lastMonthSales'] ?? 0)}',
                '${metrics['lastMonthOrders'] ?? 0} orders',
                Icons.trending_down,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Sales Growth',
                '${(metrics['salesGrowth'] ?? 0).toStringAsFixed(1)}%',
                'vs last month',
                metrics['salesGrowth'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                metrics['salesGrowth'] >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Orders Growth',
                '${(metrics['ordersGrowth'] ?? 0).toStringAsFixed(1)}%',
                'vs last month',
                metrics['ordersGrowth'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                metrics['ordersGrowth'] >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
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
}
