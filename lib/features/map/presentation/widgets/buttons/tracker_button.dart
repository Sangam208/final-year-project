import 'package:flutter/material.dart';

class TrackerButton extends StatelessWidget {
  final Color trackerColor;
  final IconData trackerIcon;
  const TrackerButton({
    super.key,
    required this.trackerColor,
    required this.trackerIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: trackerColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        trackerIcon,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
