import 'package:bus_tracker/core/common/widgets/loader.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/focus_scope.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:bus_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bus_tracker/features/auth/presentation/screens/otp_screen.dart';
import 'package:bus_tracker/features/auth/presentation/widgets/auth_button.dart';
import 'package:bus_tracker/features/auth/presentation/widgets/auth_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class AuthScreen extends StatefulWidget {
  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(
    builder: (context) => const AuthScreen(),
  );
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();

  final _phoneFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusScope(context),
      child: Scaffold(
        backgroundColor: AppTheme.kAuthColor,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              showToast(state.message);
            } else if (state is AuthSuccess) {
              Navigator.push(
                context,
                OtpScreen.route('+977${_phoneController.text.trim()}'),
              );
              showToast('OTP Sent');
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.kBlueColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 28),
                    Text('Sajilo Yatra', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Track your bus, plan your trip, and travel with confidence.', style: TextStyle(color: AppTheme.kMutedColor, height: 1.45)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: Lottie.asset(
                      'assets/lottie/moving_bus.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: AppTheme.kWhiteColor,
                      child: Form(
                        key: _phoneFormKey,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Continue with your mobile number',
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 6),
                              const Text('We will send a one-time verification code.', style: TextStyle(color: AppTheme.kMutedColor)),
                              const SizedBox(height: 18),
                              Authfield(
                                prefixText: '+977 ',
                                fieldController: _phoneController,
                                maxLength: 10,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Missing Phone Number';
                                  }
                                  if (value.length != 10) {
                                    return 'Phone number should be 10 digits long';
                                  }
                                  if (!RegExp(
                                    r'^(97|98)[0-9]{8}$',
                                  ).hasMatch(value)) {
                                    return 'Invalid number. Please try again';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthButton(
                                onPressed: () {
                                  if (state is AuthLoading) return;
                                  if (_phoneFormKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                      AuthSendOTP(
                                        '+977${_phoneController.text.trim()}',
                                      ),
                                    );
                                  }
                                },
                                child: state is AuthLoading
                                    ? const Loader()
                                    : Text(
                                        'Send verification code',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
