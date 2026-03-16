import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/focus_scope.dart';
import 'package:bus_tracker/features/auth/presentation/widgets/otp_form.dart';
import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  final String phoneNumber;

  static MaterialPageRoute<dynamic> route(String phoneNumber) =>
      MaterialPageRoute(
        builder: (context) => OtpScreen(phoneNumber: phoneNumber),
      );
  const OtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusScope(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.appColor1,
        ),
        backgroundColor: AppTheme.appColor1,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                OtpForm(
                  phoneNumber: phoneNumber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
