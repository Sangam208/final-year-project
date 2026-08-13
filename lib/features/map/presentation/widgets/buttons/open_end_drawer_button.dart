import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class OpenEndDrawerButton extends StatelessWidget {
  final void Function() onPressed;
  const OpenEndDrawerButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.menu,
        color: AppTheme.kBlackColor,
        size: 28.0,
      ),
    );
  }
}
