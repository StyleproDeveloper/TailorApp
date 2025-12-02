import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Tools/Helper.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Expenses/ExpenseStyle.dart';

import '../../../../GlobalVariables.dart';

class ExpenseEntry {
  String expenseType;
  TextEditingController amountController;
  DateTime? date;
  TextEditingController dateController;

  ExpenseEntry({
    this.expenseType = 'rent',
    required this.amountController,
    this.date,
    required this.dateController,
  });

  void dispose() {
    amountController.dispose();
    dateController.dispose();
  }
}

class Addexpensemodal extends StatefulWidget {
  const Addexpensemodal({super.key, required this.onClose, this.expenseData, this.submit});

  final VoidCallback onClose;
  final VoidCallback? submit;
  final Map<String, dynamic>? expenseData;

  @override
  _AddexpensemodalState createState() => _AddexpensemodalState();
}

class _AddexpensemodalState extends State<Addexpensemodal> {
  List<ExpenseEntry> expenseEntries = [];

  @override
  void initState() {
    super.initState();
    if (widget.expenseData != null) {
      // Load expense entries if they exist
      if (widget.expenseData!['entries'] != null && 
          (widget.expenseData!['entries'] as List).isNotEmpty) {
        final entries = widget.expenseData!['entries'] as List<dynamic>;
        for (var entry in entries) {
          final amountController = TextEditingController(
            text: (entry['amount'] ?? 0).toString(),
          );
          final dateController = TextEditingController();
          DateTime? date;
          if (entry['date'] != null) {
            try {
              date = DateTime.parse(entry['date']);
              dateController.text = DateFormat('yyyy-MM-dd').format(date);
            } catch (e) {
              date = DateTime.now();
              dateController.text = DateFormat('yyyy-MM-dd').format(date);
            }
          } else {
            date = DateTime.now();
            dateController.text = DateFormat('yyyy-MM-dd').format(date);
          }
          
          expenseEntries.add(ExpenseEntry(
            expenseType: entry['expenseType'] ?? 'rent',
            amountController: amountController,
            date: date,
            dateController: dateController,
          ));
        }
      } else {
        // If no entries, add one empty row
        _addExpenseEntry();
      }
    } else {
      // New expense - add one empty row
      _addExpenseEntry();
    }
  }

  void _addExpenseEntry() {
    setState(() {
      final dateController = TextEditingController();
      final now = DateTime.now();
      dateController.text = DateFormat('yyyy-MM-dd').format(now);
      
      expenseEntries.add(ExpenseEntry(
        expenseType: 'rent',
        amountController: TextEditingController(),
        date: now,
        dateController: dateController,
      ));
    });
  }

  void _removeExpenseEntry(int index) {
    setState(() {
      expenseEntries[index].dispose();
      expenseEntries.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expenseEntries[index].date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        expenseEntries[index].date = picked;
        expenseEntries[index].dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void handleSaveRole() async {
    int? id = GlobalVariables.shopIdGet;
    int? expenseId = widget.expenseData?['expenseId'];
    if (id == null) {
      Future.microtask(() => CustomSnackbar.showSnackbar(
            context,
            "Shop ID is missing",
            duration: Duration(seconds: 2),
          ));
      return;
    }
    
    // Validate entries
    for (int i = 0; i < expenseEntries.length; i++) {
      final entry = expenseEntries[i];
      if (entry.amountController.text.isEmpty || 
          double.tryParse(entry.amountController.text) == null ||
          double.tryParse(entry.amountController.text)! <= 0) {
        CustomSnackbar.showSnackbar(
          context,
          'Please enter a valid amount for row ${i + 1}',
          duration: const Duration(seconds: 2),
        );
        return;
      }
      if (entry.date == null) {
        CustomSnackbar.showSnackbar(
          context,
          'Please select a date for row ${i + 1}',
          duration: const Duration(seconds: 2),
        );
        return;
      }
    }
    
    try {
      showLoader(context);
      
      // Build entries array
      final entries = expenseEntries.map((entry) => {
        'expenseType': entry.expenseType,
        'amount': double.parse(entry.amountController.text),
        'date': entry.date!.toIso8601String(),
      }).toList();
      
      // Get owner name from GlobalVariables (roleName or userId as fallback)
      String? ownerName = GlobalVariables.roleName ?? 
                          (GlobalVariables.userId != null ? 'User ${GlobalVariables.userId}' : null);
      
      final payload = {
        'shop_id': id,
        'entries': entries,
        if (ownerName != null) 'owner': ownerName,
      };
      
      Response response;
      if (widget.expenseData != null) {
        final requestUrl = "${Urls.expense}/$id/$expenseId";
        response = await ApiService().put(requestUrl, data: payload, context);
      } else {
        response = await ApiService().post(Urls.expense, data: payload, context);
      }
      hideLoader(context);
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('message')) {
        CustomSnackbar.showSnackbar(
          context,
          response.data['message'],
          duration: const Duration(seconds: 1),
        );
        widget.onClose();
        widget.submit!();
      } else {
        CustomSnackbar.showSnackbar(
          context,
          'Expense not saved',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      hideLoader(context);
      CustomSnackbar.showSnackbar(
        context,
        'Error saving expense: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    for (var entry in expenseEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.expenseData != null ? 'Edit Expense' : 'Add Expense',
                      style: Expensestyle.headerExpense,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Expense entries - vertical layout for mobile
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: expenseEntries.length,
                    itemBuilder: (context, index) {
                      final entry = expenseEntries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Entry ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: ColorPalatte.primary,
                                  ),
                                ),
                                if (expenseEntries.length > 1)
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeExpenseEntry(index),
                                    tooltip: 'Remove entry',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Expense Type Dropdown
                            Text(
                              'Expense Type',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: entry.expenseType,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: ['rent', 'electricity', 'salary', 'miscellaneous']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type[0].toUpperCase() + type.substring(1),
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  entry.expenseType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Amount Field
                            Text(
                              'Amount (₹)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: entry.amountController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: '0.00',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            // Date Field
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: entry.dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: Icon(Icons.calendar_today, size: 20),
                                hintText: 'Select date',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(fontSize: 14),
                              onTap: () => _selectDate(context, index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Add Entry Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addExpenseEntry,
                    icon: Icon(Icons.add, color: ColorPalatte.primary),
                    label: Text(
                      'Add Entry',
                      style: TextStyle(color: ColorPalatte.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Save Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: handleSaveRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalatte.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                    ),
                    child: widget.expenseData != null
                        ? const Text(
                            'Update Expense',
                            style: Expensestyle.saveBtnExpense,
                          )
                        : const Text(
                            'Save Expense',
                            style: Expensestyle.saveBtnExpense,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
