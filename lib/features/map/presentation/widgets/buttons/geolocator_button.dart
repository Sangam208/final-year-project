import 'package:flutter/material.dart';

class GeolocatorButton extends StatelessWidget {
  final Color backgroundColor;
  final void Function()? onPressed;
  final IconData icon;
  final Color iconColor;
  const GeolocatorButton({
    super.key,
    required this.backgroundColor,
    this.onPressed,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: backgroundColor,
      onPressed: onPressed,
      child: Icon(Icons.my_location, color: iconColor),
    );
  }
}
