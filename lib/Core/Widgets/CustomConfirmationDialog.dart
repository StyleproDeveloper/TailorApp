import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Widgets/CommonStyles.dart';

class CustomConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color cancelColor;
  final Color confirmColor;
  final Color cancelBorderColor;
  final double cancelBorderWidth;

  const CustomConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelText = "Cancel",
    this.confirmText = "Confirm",
    this.onConfirm,
    this.onCancel,
    this.cancelColor = ColorPalatte.white,
    this.confirmColor = ColorPalatte.primary,
    this.cancelBorderColor = ColorPalatte.primary,
    this.cancelBorderWidth = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorPalatte.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: Commonstyles.alertTitle,
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: Commonstyles.alertSubtitle,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (onCancel != null) onCancel!();
          },
          style: TextButton.styleFrom(
            backgroundColor: cancelColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: cancelBorderColor,
                width: cancelBorderWidth,
              ),
            ),
          ),
          child: Text(cancelText, style: Commonstyles.alertCancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (onConfirm != null) onConfirm!();
          },
          style: TextButton.styleFrom(
            backgroundColor: confirmColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(confirmText, style: Commonstyles.alertSubmit),
        ),
      ],
    );
  }
}
