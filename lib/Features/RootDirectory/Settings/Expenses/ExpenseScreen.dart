import 'dart:async';

import 'package:flutter/material.dart';
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
      BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Addexpensemodal(
        expenseData: userData,
        onClose: () {
          Navigator.of(context).pop();
        },
        submit: () {
          _fetchExpenseData();
        },
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
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: expenses.length + (hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == expenses.length) {
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
                        final expense = expenses[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(expense['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle:
                                Text("Expense ID: ${expense['expenseId']}"),
                            leading: const Icon(Icons.money,
                                color: ColorPalatte.primary),
                            onTap: () =>
                                _showEditExpenseModal(context, expense),
                          ),
                        );
                      },
                    ),
            )
          ],
        ));
  }
}
