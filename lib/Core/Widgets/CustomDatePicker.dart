import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';

class CustomDatePicker extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool allowFutureOnly;

  const CustomDatePicker({
    super.key,
    required this.label,
    required this.controller,
    this.allowFutureOnly = false,
  });

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.allowFutureOnly ? today.add(Duration(days: 1)) : DateTime.now(),
      firstDate: widget.allowFutureOnly ? today : DateTime(1900),
      lastDate: widget.allowFutureOnly ? DateTime(2100) : today,
    );

    if (pickedDate != null) {
      setState(() {
        widget.controller.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: widget.controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(
            color: ColorPalatte.black,
          ),
          hintText: "Select Date",
          hintStyle: TextStyle(color: ColorPalatte.borderGray),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_month, color: ColorPalatte.primary),
            onPressed: () => _selectDate(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ColorPalatte.borderGray, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ColorPalatte.borderGray, width: 1),
          ),
        ),
        onTap: () => _selectDate(context),
      ),
    );
  }
}
