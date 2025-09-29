import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({Key? key, required this.isLoading, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Stack(
              children: [
                // Blurred background
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: ColorPalatte.black.withOpacity(0.3),
                  ),
                ),
                // Loader in the center
                const Center(
                  child: CircularProgressIndicator(
                    color: ColorPalatte.black,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
