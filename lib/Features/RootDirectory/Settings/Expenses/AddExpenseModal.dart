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
  final TextEditingController nameController = TextEditingController();
  List<ExpenseEntry> expenseEntries = [];

  @override
  void initState() {
    super.initState();
    if (widget.expenseData != null) {
      nameController.text = widget.expenseData!['name']?.trim() ?? '';
      
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
    if (nameController.text.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        'Expense name is required',
        duration: const Duration(seconds: 1),
      );
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
        return {
          'expenseType': entry.expenseType,
          'amount': double.parse(entry.amountController.text),
          'date': entry.date!.toIso8601String(),
        };
      }).toList();
      
      final payload = {
        'shop_id': id,
        'name': capitalize(nameController.text),
        'entries': entries,
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
    nameController.dispose();
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
                TextField(
                  controller: nameController,
                  style: Expensestyle.expenseText,
                  decoration: InputDecoration(
                    labelText: 'Expense Name',
                    labelStyle: Expensestyle.expenseText,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: ColorPalatte.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Expense Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: ColorPalatte.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Amount (₹)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                            fontSize: 14,
                            color: ColorPalatte.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 40), // Space for delete button
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Expense entries table
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: expenseEntries.length,
                    itemBuilder: (context, index) {
                      final entry = expenseEntries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            // Expense Type Dropdown
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: entry.expenseType,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
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
                            ),
                            const SizedBox(width: 8),
                            // Amount Field
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: entry.amountController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  hintText: '0.00',
                                ),
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Date Field
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: entry.dateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                  hintText: 'Select date',
                                ),
                                style: TextStyle(fontSize: 14),
                                onTap: () => _selectDate(context, index),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete Button
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: expenseEntries.length > 1
                                  ? () => _removeExpenseEntry(index)
                                  : null,
                              tooltip: 'Remove row',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Add Row Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addExpenseEntry,
                    icon: Icon(Icons.add, color: ColorPalatte.primary),
                    label: Text(
                      'Add Row',
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
