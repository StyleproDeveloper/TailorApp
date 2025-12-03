import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Expenses/AddExpenseModal.dart';
import '../../../../Core/Constants/ColorPalatte.dart';
import '../../../../Core/Widgets/CommonHeader.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';
import '../../../../GlobalVariables.dart';

class Expensescreen extends StatefulWidget {
  const Expensescreen({super.key});

  @override
  State<Expensescreen> createState() => _ExpensescreenState();
}

class _ExpensescreenState extends State<Expensescreen> {
  bool isLoading = false;
  List<Map<String, dynamic>> expenses = [];
  bool _isFetched = false;
  final ScrollController _scrollController = ScrollController();
  int pageNumber = 1;
  final int pageSize = 10;
  bool hasMoreData = true;
  TextEditingController searchKeywordController = TextEditingController();
  Timer? _debounce;
  bool _isInitialFetch = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isFetched) {
      _fetchExpenseData();
      _isFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchExpenseData();
        _scrollController.addListener(_scrollListener);
        searchKeywordController.addListener(_onSearchChanged);
      });
    }
  }

  void _scrollListener() {
    if (!isLoading &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      _fetchExpenseData();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        expenses.clear();
        pageNumber = 1;
        hasMoreData = true;
      });
      _fetchExpenseData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchKeywordController.dispose();
    super.dispose();
  }

  void _showAddRoleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Addexpensemodal(
        onClose: () => {Navigator.of(context).pop()},
        submit: () {
          // Refresh the list immediately
          setState(() {
            expenses.clear();
            pageNumber = 1;
            hasMoreData = true;
            isLoading = false;
          });
          _fetchExpenseData();
        },
      ),
    );
  }

  void _fetchExpenseData() async {
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
        "${Urls.expense}/$id?pageNumber=$pageNumber&pageSize=$pageSize&searchKeyword=${searchKeywordController.text}";

    try {
      if (_isInitialFetch && pageNumber == 1) {
        Future.delayed(Duration.zero, () => showLoader(context));
      }
      final response = await ApiService().get(requestUrl, context);
      if (_isInitialFetch && pageNumber == 1) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }

      if (response.data is Map<String, dynamic>) {
        List<dynamic> expenseData = response.data['data'];

        setState(() {
          expenses.addAll(expenseData.map((expense) {
            return {
              'name': expense['name'] ?? 'Unknown Expense',
              'expenseId': expense['expenseId'] ?? 'N/A',
              'entries': expense['entries'] ?? [],
              'owner': expense['owner'] ?? null,
              // Keep old fields for backward compatibility
              'rent': expense['rent'] ?? 0,
              'electricity': expense['electricity'] ?? 0,
              'salary': expense['salary'] ?? 0,
              'miscellaneous': expense['miscellaneous'] ?? 0,
            };
          }));
          if (expenseData.length < pageSize) {
            hasMoreData = false;
          } else {
            pageNumber++;
          }
          isLoading = false;
          _isInitialFetch = false;
        });
      } else {
        Future.microtask(() => CustomSnackbar.showSnackbar(
              context,
              'Expense not found',
              duration: const Duration(seconds: 1),
            ));
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (_isInitialFetch && pageNumber == 1) {
        Future.delayed(Duration.zero, () => hideLoader(context));
      }
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            'Failed to load expenses',
            duration: Duration(seconds: 2),
          ));
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showEditExpenseModal(
      BuildContext context, Map<String, dynamic> expenseData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Addexpensemodal(
        expenseData: expenseData,
        onClose: () {
          Navigator.of(context).pop();
        },
        submit: () {
          _fetchExpenseData();
        },
      ),
    );
  }
  
  Widget _buildExpenseRow(String label, dynamic amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            '₹${(amount is num ? amount : 0).toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // Group expenses by month and build the list
  Widget _buildGroupedExpenseList() {
    // Group expenses by month-year
    Map<String, List<Map<String, dynamic>>> groupedExpenses = {};
    
    for (var expense in expenses) {
      final entries = expense['entries'] as List<dynamic>? ?? [];
      
      // Get the earliest date from entries to determine the month
      DateTime? expenseDate;
      if (entries.isNotEmpty) {
        try {
          final firstEntry = entries.first;
          if (firstEntry['date'] != null) {
            expenseDate = DateTime.parse(firstEntry['date']);
          }
        } catch (e) {
          // If parsing fails, use createdAt or current date
          expenseDate = expense['createdAt'] != null 
              ? DateTime.parse(expense['createdAt']) 
              : DateTime.now();
        }
      } else {
        // Fallback to createdAt or current date
        expenseDate = expense['createdAt'] != null 
            ? DateTime.parse(expense['createdAt']) 
            : DateTime.now();
      }
      
      if (expenseDate == null) expenseDate = DateTime.now();
      
      // Create month-year key (e.g., "December 2025")
      final monthKey = DateFormat('MMMM yyyy').format(expenseDate);
      
      if (!groupedExpenses.containsKey(monthKey)) {
        groupedExpenses[monthKey] = [];
      }
      groupedExpenses[monthKey]!.add(expense);
    }
    
    // Sort month keys in descending order (newest first)
    final sortedMonths = groupedExpenses.keys.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMMM yyyy').parse(a);
          final dateB = DateFormat('MMMM yyyy').parse(b);
          return dateB.compareTo(dateA); // Descending order
        } catch (e) {
          return b.compareTo(a);
        }
      });
    
    // Build list items
    List<Widget> listItems = [];
    int totalItemCount = 0;
    
    for (var monthKey in sortedMonths) {
      final monthExpenses = groupedExpenses[monthKey]!;
      
      // Add month header
      listItems.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: ColorPalatte.primary.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: ColorPalatte.primary.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: ColorPalatte.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                monthKey,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPalatte.primary,
                ),
              ),
            ],
          ),
        ),
      );
      
      // Add expenses for this month
      for (var expense in monthExpenses) {
        listItems.add(_buildExpenseCard(expense));
        totalItemCount++;
      }
    }
    
    // Add loading indicator if there's more data
    if (hasMoreData) {
      listItems.add(
        const Padding(
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
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final entries = expense['entries'] as List<dynamic>? ?? [];
    
    // Calculate total expense from entries
    double total = 0;
    if (entries.isNotEmpty) {
      total = entries.fold<double>(
        0,
        (sum, entry) => sum + ((entry['amount'] ?? 0) as num).toDouble(),
      );
    } else {
      // Fallback to old structure for backward compatibility
      total = (expense['rent'] ?? 0) +
          (expense['electricity'] ?? 0) +
          (expense['salary'] ?? 0) +
          (expense['miscellaneous'] ?? 0);
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _showEditExpenseModal(context, expense),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.money, color: ColorPalatte.primary),
                      const SizedBox(width: 8),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ColorPalatte.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isNotEmpty) ...[
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: ColorPalatte.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: ColorPalatte.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: ColorPalatte.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: ColorPalatte.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Table rows
                ...entries.map((entry) {
                  final type = (entry['expenseType'] ?? 'rent').toString();
                  final amount = (entry['amount'] ?? 0) as num;
                  final dateStr = entry['date'] ?? '';
                  String formattedDate = '';
                  try {
                    if (dateStr.isNotEmpty) {
                      final date = DateTime.parse(dateStr);
                      formattedDate = DateFormat('yyyy-MM-dd').format(date);
                    }
                  } catch (e) {
                    formattedDate = dateStr;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ] else ...[
                // Fallback to old structure display
                if (expense['rent'] != null && expense['rent'] > 0)
                  _buildExpenseRow('Rent', expense['rent']),
                if (expense['electricity'] != null && expense['electricity'] > 0)
                  _buildExpenseRow('Electricity', expense['electricity']),
                if (expense['salary'] != null && expense['salary'] > 0)
                  _buildExpenseRow('Salary', expense['salary']),
                if (expense['miscellaneous'] != null && expense['miscellaneous'] > 0)
                  _buildExpenseRow('Miscellaneous', expense['miscellaneous']),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ID: ${expense['expenseId']}",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600]),
                  ),
                  if (expense['owner'] != null && expense['owner'].toString().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          "Added by: ${expense['owner']}",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic),
                        ),
                      ],
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
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Commonheader(
          title: 'Expense',
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                onPressed: () {
                  _showAddRoleModal(context);
                },
                icon: const Icon(Icons.add, color: ColorPalatte.primary),
                label: const Text('Add Expense',
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
                  hintText: "Search expenses...",
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
            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text("No expenses found"))
                  : _buildGroupedExpenseList(),
            )
          ],
        ));
  }
}
