import 'package:flutter/material.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.kBlueColor,
      ),
    );
  }
}
