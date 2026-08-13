import 'dart:async';

import 'package:bus_tracker/core/common/widgets/loader.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/focus_scope.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:bus_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bus_tracker/features/auth/presentation/widgets/auth_button.dart';
import 'package:bus_tracker/features/auth/presentation/widgets/auth_field.dart';
import 'package:bus_tracker/features/map/presentation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class OtpScreen extends StatefulWidget {
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
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  final _otpFormKey = GlobalKey<FormState>();

  int timeLeft = 59;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _startCountDown();
    super.initState();
  }

  void _startCountDown() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (timeLeft > 0) {
          setState(() {
            timeLeft--;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusScope(context),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.kAuthColor,
        ),
        backgroundColor: AppTheme.kAuthColor,
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                showToast(state.message);
              } else if (state is AuthUserSuccess) {
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MapScreen.route(),
                  (route) => false,
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'B u s   T r a c k e r',
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                color: AppTheme.kBlueColor,
                                fontSize: 35,
                              ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Lottie.asset(
                        'assets/lottie/otp.json',
                        width: double.infinity,
                        height: 310,
                      ),

                      const SizedBox(height: 18),

                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(12.0),
                          side: BorderSide(
                            color: AppTheme.appColor1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        color: AppTheme.appColor2,
                        child: Form(
                          key: _otpFormKey,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'E n t e r   O T P',
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium!.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Authfield(
                                        fieldController: _otpController,
                                        maxLength: 6,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Missing OTP';
                                          }
                                          if (value.length != 6) {
                                            return 'OTP should of 6 digits long';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.kBlueColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.kBlueColor.withValues(
                                            alpha: 0.25,
                                          ),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        "0:${timeLeft.toString().padLeft(2, '0')}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.kBlueColor,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                AuthButton(
                                  onPressed: () {
                                    if (state is AuthLoading) null;
                                    if (_otpFormKey.currentState!.validate()) {
                                      context.read<AuthBloc>().add(
                                        AuthVerifyOTP(
                                          widget.phoneNumber,
                                          _otpController.text.trim(),
                                        ),
                                      );
                                    }
                                  },
                                  child: state is AuthLoading
                                      ? const Loader()
                                      : Text(
                                          'C o n f i r m',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium!.copyWith(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 16,
                                                color: AppTheme.kWhiteColor,
                                              ),
                                        ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
