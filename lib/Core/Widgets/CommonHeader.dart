import 'package:flutter/material.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Widgets/CommonStyles.dart';

class Commonheader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onPressed;
  final List<Widget> actions;
  final double height;
  final bool showBackArrow;
  final Icon? backArrowIcon;
  final bool backArrowdisable;
  final int? titleSpacing;
  final Widget? leading;

  const Commonheader({
    super.key,
    required this.title,
    this.actions = const [],
    this.height = 45.0,
    this.onPressed,
    this.showBackArrow = true,
    this.backArrowIcon,
    this.backArrowdisable = true,
    this.titleSpacing = 0,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: Commonstyles.headerText),
      automaticallyImplyLeading: showBackArrow,
      backgroundColor: ColorPalatte.white,
      elevation: 0,
      titleSpacing: titleSpacing?.toDouble(),
      actions: actions,
      leading: leading ?? (showBackArrow
          ? IconButton(
              icon: backArrowIcon ??
                  const Icon(Icons.arrow_back_ios,
                      color: ColorPalatte.black, size: 19),
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
            )
          : null),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: ColorPalatte.borderGray,
          height: 0.5,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + 1);
}
