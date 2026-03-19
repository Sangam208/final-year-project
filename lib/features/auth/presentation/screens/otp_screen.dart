import 'package:bus_tracker/core/common/widgets/loader.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/focus_scope.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:bus_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bus_tracker/features/auth/presentation/widgets/auth_textfield.dart';
import 'package:bus_tracker/features/map/presentation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusScope(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.appColor1,
        ),
        backgroundColor: AppTheme.appColor1,
        body: BlocConsumer<AuthBloc, AuthState>(
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Card(
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
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              Text(
                                'E n t e r   O T P',
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Authfield(
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
                              const SizedBox(height: 15),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      12,
                                    ),
                                  ),
                                  minimumSize: Size(double.infinity, 50.0),
                                ),
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
                                        'C O N F I R M',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
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
    );
  }
}
