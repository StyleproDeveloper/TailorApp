import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Constants/TextString.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Features/RootDirectory/Settings/contactUs/ContactSupportStyles.dart';
import 'contactSupportController.dart';

class ContactSupportScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(contactSupportProvider);
    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(title: Textstring().contactSupport),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(Textstring().howcanwehelp,
                      style: Contactsupportstyles.header),
                ),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(controller.nameController, "Full Name"),
                        _buildTextField(
                            controller.emailController, "Email Address"),
                        _buildDropdown(controller, context),
                        _buildMessageField(controller.messageController),
                        SizedBox(height: 20),
                        _buildSendButton(controller, context),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildWhatsAppSupport(context),
                SizedBox(height: 20),
                _buildContactOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTextField(TextEditingController controller, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ColorPalatte.primary,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
    ),
  );
}

Widget _buildDropdown(
    ContactSupportController controller, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: DropdownButtonFormField<String>(
      value: controller.selectedSubject,
      items: ["Billing Issue", "Technical Support", "General Inquiry"].map((e) {
        return DropdownMenuItem(value: e, child: Text(e));
      }).toList(),
      onChanged: (value) => controller.setSubject(value!),
      decoration: InputDecoration(
        labelText: "Subject",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ColorPalatte.primary,
            width: 0.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    ),
  );
}

Widget _buildMessageField(TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: TextField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: "Message",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ColorPalatte.primary,
            width: 0.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    ),
  );
}

Widget _buildSendButton(
    ContactSupportController controller, BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: Icon(Icons.send, color: Colors.white),
      label: Text(
        "Send Message",
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalatte.primary,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3, // Slight shadow effect
      ),
      onPressed: () => controller.submitForm(context),
    ),
  );
}

Widget _buildWhatsAppSupport(BuildContext context) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * 0.95,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
            SizedBox(width: 10),
            Text("Need immediate help?",
                style: TextStyle(fontWeight: FontWeight.bold))
          ]),
          SizedBox(height: 10),
          Text("Chat with our support team on WhatsApp"),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: Icon(FontAwesomeIcons.whatsapp),
              label: Text("Chat on WhatsApp"),
              onPressed: () {},
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildContactOptions() {
  return Column(
    children: [
      Text("Available 24/7 for your queries"),
      SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(children: [
            Icon(Icons.phone, color: Colors.blue),
            Text("Call Support"),
            Text("+1 (555) 123-4567")
          ]),
          Column(children: [
            Icon(Icons.email, color: Colors.blue),
            Text("Email Support"),
            Text("support@example.com")
          ]),
        ],
      ),
    ],
  );
}
