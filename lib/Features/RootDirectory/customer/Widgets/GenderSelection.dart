import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/Fonts.dart';
import '../../../../Core/Constants/ColorPalatte.dart';

class GenderSelection extends StatefulWidget {
  final Function(String) onGenderSelected;
  final String? initialGender;

  const GenderSelection({super.key, required this.onGenderSelected, this.initialGender});

  @override
  _GenderSelectionState createState() => _GenderSelectionState();
}

class _GenderSelectionState extends State<GenderSelection> {
  String selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    if (widget.initialGender != null) {
      selectedGender = _capitalizeGender(widget.initialGender!);
      print('🎯 GenderSelection initState: ${widget.initialGender} -> $selectedGender');
    }
  }

  @override
  void didUpdateWidget(GenderSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialGender != null && widget.initialGender != oldWidget.initialGender) {
      setState(() {
        selectedGender = _capitalizeGender(widget.initialGender!);
      });
      print('🎯 GenderSelection didUpdateWidget: ${oldWidget.initialGender} -> ${widget.initialGender} = $selectedGender');
    }
  }

  String _capitalizeGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return 'Male';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: const Text(
            "Gender *",
            style: TextStyle(
              fontSize: 14,
              fontFamily: Fonts.Medium,
              color: ColorPalatte.gray,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildGenderRadio("Male"),
            _buildGenderRadio("Female"),
            _buildGenderRadio("Other"),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderRadio(String gender) {
    return Row(
      children: [
        Radio<String>(
          value: gender,
          groupValue: selectedGender,
          onChanged: (value) {
            setState(() {
              selectedGender = value!;
            });
            widget.onGenderSelected(value!);
          },
          activeColor: ColorPalatte.primary,
        ),
        Text(
          gender,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
