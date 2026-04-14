import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const AuthButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(
            12,
          ),
        ),
        minimumSize: Size(double.infinity, 50.0),
        backgroundColor: AppTheme.kBlueColor,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
