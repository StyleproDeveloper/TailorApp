import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';

void showLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Stack(
        children: [
          // Blurred background overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Centered loading dialog
          Center(
              child: SizedBox(
                width: 45, // Fixed background width
                height: 45, // Fixed background height
                child: Center(
                  child: SizedBox(
                    width: 20, // Loader width
                    height: 20, // Loader height
                    child: CircularProgressIndicator(
                      color: ColorPalatte.primary, // Primary color loader
                      strokeWidth: 2.5, // Adjust thickness if needed
                    ),
                  ),
                ),
            ),
          ),
        ],
      );
    },
  );
}

void hideLoader(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}