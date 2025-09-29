// contact_support_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactSupportProvider = ChangeNotifierProvider((ref) => ContactSupportController());

class ContactSupportController extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  String selectedSubject = "Billing Issue";

  void setSubject(String value) {
    selectedSubject = value;
    notifyListeners();
  }

  void submitForm(BuildContext context) {
    if (nameController.text.isEmpty || emailController.text.isEmpty || messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All fields are required!")));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Message sent successfully!")));
    _clearForm();
  }

  void _clearForm() {
    nameController.clear();
    emailController.clear();
    messageController.clear();
    selectedSubject = "Billing Issue";
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
