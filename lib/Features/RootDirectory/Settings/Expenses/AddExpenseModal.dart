import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Tools/Helper.dart';
import 'package:tailorapp/Core/Widgets/CustomLoader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/Expenses/ExpenseStyle.dart';

import '../../../../GlobalVariables.dart';

class Addexpensemodal extends StatefulWidget {
  const Addexpensemodal({super.key, required this.onClose, this.expenseData, this.submit});

  final VoidCallback onClose;
  final VoidCallback? submit;
  final Map<String, dynamic>? expenseData;

  @override
  _AddexpensemodalState createState() => _AddexpensemodalState();
}

class _AddexpensemodalState extends State<Addexpensemodal> {
  final TextEditingController roleNameController = TextEditingController();

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
    if (roleNameController.text.isEmpty) {
      CustomSnackbar.showSnackbar(
        context,
        'Expense name is required',
        duration: const Duration(seconds: 1),
      );
      return;
    }
    try {
      showLoader(context);
      final payload = {
        'shop_id': id,
        'name': capitalize(roleNameController.text),
        // 'owner': 'test'
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
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.expenseData != null) {
      roleNameController.text = widget.expenseData!['name']?.trim() ?? '';
    }
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
                controller: roleNameController,
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
    );
  }
}
