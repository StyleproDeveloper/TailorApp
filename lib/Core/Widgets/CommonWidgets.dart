import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Features/RootDirectory/Orders/CreateOrder/CreateOrderStyle.dart';

Widget buildDropdown<T>({
  required String hint,
  required T? value,
  required List<T> items,
  required void Function(T) onChanged,
}) {
  return DropdownButtonFormField<T>(
    value: items.contains(value) ? value : null,
    hint: Text(hint),
    items: items.isEmpty
        ? [
            DropdownMenuItem<T>(
              value: null,
              child: Text('No $hint available'),
              enabled: false,
            ),
          ]
        : items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item is Map<String, dynamic> ? item['name'].toString() : item.toString(),
              ),
            );
          }).toList(),
    onChanged: items.isEmpty ? null : (newValue) => onChanged(newValue!),
    decoration: InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

Widget buildTextField({
  required String hint,
  IconData? icon,
  int? maxLines,
  int? maxLength,
  int minLines = 1,
  TextEditingController? controller,
  TextInputType keyboardType = TextInputType.text,
  bool enabled = true,
  void Function(String)? onChanged,
}) {
  return TextField(
    controller: controller,
    onChanged: onChanged,
    style: Createorderstyle.cuttingValuesText,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    keyboardType: keyboardType,
    enabled: enabled,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: ColorPalatte.borderGray),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: ColorPalatte.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ColorPalatte.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
  );
}

Widget buildButton({required String text, VoidCallback? onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalatte.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(text, style: Createorderstyle.buttonsText),
    ),
  );
}

Widget buildIconButton({required IconData icon, required VoidCallback onPressed}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ColorPalatte.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    ),
  );
}

Widget buildAdditionalCostField({
  required TextEditingController descriptionController,
  required TextEditingController amountController,
  VoidCallback? onRemove,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: buildTextField(
            hint: "Item description",
            controller: descriptionController,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: buildTextField(
            hint: "Amount",
            controller: amountController,
            keyboardType: TextInputType.number,
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ],
      ),
    );
}

class ImagePickerOptions extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const ImagePickerOptions({super.key, required this.onCameraTap, required this.onGalleryTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Open Camera"),
            onTap: onCameraTap,
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Select from Gallery"),
            onTap: onGalleryTap,
          ),
        ],
      ),
    );
  }
}