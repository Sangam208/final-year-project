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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size(double.infinity, 54),
        backgroundColor: AppTheme.kBlueColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
