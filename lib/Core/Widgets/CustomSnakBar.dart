import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Widgets/CommonStyles.dart';

class CustomSnackbar {
  static void showSnackbar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return CustomSnackbarContent(
          message: message,
          duration: duration,
          onDismiss: () => entry.remove(),
        );
      },
    );

    // Insert the overlay
    overlay.insert(entry);
  }
}

class CustomSnackbarContent extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  CustomSnackbarContent({required this.message, required this.duration, required this.onDismiss});

  @override
  _CustomSnackbarContentState createState() => _CustomSnackbarContentState();
}

class _CustomSnackbarContentState extends State<CustomSnackbarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, 1), // Start from bottom
      end: Offset(0, 0),   // Move to visible position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10.0,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Center(
              child: Text(widget.message, style: Commonstyles.snackBarText),
            ),
          ),
        ),
      ),
    );
  }
}
