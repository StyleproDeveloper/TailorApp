import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String capitalize(String name) {
  name = name.trim();
  if (name.isEmpty) return '';
  return name[0].toUpperCase() + name.substring(1);
}

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    DateTime date;
    
    // Handle ISO format from API: 1991-12-03T00:00:00.000Z
    if (dateStr.contains('T') || dateStr.contains('Z')) {
      date = DateTime.parse(dateStr);
    }
    // Handle yyyy-MM-dd format
    else if (dateStr.contains('-') && dateStr.length >= 10) {
      date = DateTime.parse(dateStr);
    }
    // Handle dd/MM/yyyy format
    else if (dateStr.contains('/')) {
      date = DateFormat('dd/MM/yyyy').parse(dateStr);
    }
    else {
      return '';
    }
    
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    print('Error parsing date: $e for input: $dateStr');
    return '';
  }
}

String formatDateForApi(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    // Handle different date formats
    DateTime date;
    if (dateStr.contains('/')) {
      // Format: dd/MM/yyyy
      date = DateFormat('dd/MM/yyyy').parse(dateStr);
    } else if (dateStr.contains('-')) {
      // Format: yyyy-MM-dd
      date = DateTime.parse(dateStr);
    } else {
      return '';
    }
    return DateFormat('yyyy-MM-dd').format(date);
  } catch (e) {
    print('Error parsing date for API: $e');
    return '';
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
