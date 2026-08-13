import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DestinationField extends StatelessWidget {
  final TextEditingController destinationController;
  final Future<void> Function(String location) onSubmitted;

  const DestinationField({
    super.key,
    required this.destinationController,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.kWhiteColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: TextField(
          controller: destinationController,
          decoration: InputDecoration(
            hintText: 'Enter destination location',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                width: 2.0,
                color: AppTheme.kBlueColor,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }
}
