import 'package:bus_tracker/core/common/widgets/loader.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/focus_scope.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:bus_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bus_tracker/features/auth/presentation/screens/otp_screen.dart';
import 'package:bus_tracker/features/auth/presentation/widgets/auth_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        appBar: AppBar(
          backgroundColor: AppTheme.appColor1,
        ),
        backgroundColor: AppTheme.appColor1,
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
            return state is AuthLoading
                ? const Loader()
                : Center(
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
                              key: _phoneFormKey,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    const Text(
                                      'E n t e r   P h o n e   N u m b e r',
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Authfield(
                                      prefixText: '+977',
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
                                    const SizedBox(height: 15),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(
                                                12,
                                              ),
                                        ),
                                        minimumSize: Size(
                                          double.infinity,
                                          50.0,
                                        ),
                                      ),
                                      onPressed: () {
                                        if (state is AuthLoading) null;
                                        if (_phoneFormKey.currentState!
                                            .validate()) {
                                          context.read<AuthBloc>().add(
                                            AuthSendOTP(
                                              '+977${_phoneController.text.trim()}',
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        'S e n d   O T P',
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
