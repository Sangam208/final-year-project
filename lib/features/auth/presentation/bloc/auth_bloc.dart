import 'dart:async';

import 'package:bus_tracker/core/cubits/app_user/app_user_cubit.dart';
import 'package:bus_tracker/core/usecase/usecase.dart';
import 'package:bus_tracker/features/auth/domain/entities/user.dart';
import 'package:bus_tracker/features/auth/domain/usecases/current_user.dart';
import 'package:bus_tracker/features/auth/domain/usecases/user_logout.dart';
import 'package:bus_tracker/features/auth/domain/usecases/user_send_otp.dart';
import 'package:bus_tracker/features/auth/domain/usecases/user_verify_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSendOTP _userSendOTP;
  final UserVerifyOtp _userVerifyOtp;
  final CurrentUser _currentUser;
  final AppUserCubit _appUserCubit;
  final UserLogout _userLogout;

  late final StreamSubscription<void> _logoutSubscription;

  AuthBloc({
    required UserSendOTP userSendOTP,
    required UserVerifyOtp userVerifyOtp,
    required CurrentUser currentUser,
    required AppUserCubit appUserCubit,
    required UserLogout userLogOut,
  }) : _userSendOTP = userSendOTP,
       _userVerifyOtp = userVerifyOtp,
       _currentUser = currentUser,
       _appUserCubit = appUserCubit,
       _userLogout = userLogOut,
       super(AuthInitial()) {
    on<AuthEvent>((_, emit) => emit(AuthLoading()));
    on<AuthSendOTP>(_onAuthSendOTP);
    on<AuthVerifyOTP>(_onAuthVerifyOTP);
    on<AuthCurrentUser>(_isUserExists);
    on<AuthLogOut>(_onAuthLogOut);

    _logoutSubscription = _appUserCubit.logoutRequested.listen(
      (_) => add(AuthLogOut()),
    );
  }

  @override
  Future<void> close() async {
    await _logoutSubscription.cancel();
    await super.close();
  }

  void _onAuthSendOTP(AuthSendOTP event, Emitter<AuthState> emit) async {
    final res = await _userSendOTP(
      UserSendParams(phoneNumber: event.phoneNumber),
    );

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => emit(AuthSuccess()),
    );
  }

  void _onAuthVerifyOTP(AuthVerifyOTP event, Emitter<AuthState> emit) async {
    final res = await _userVerifyOtp(
      UserVerifyParams(phoneNumber: event.phoneNumber, token: event.token),
    );

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => emit(AuthUserSuccess(r)),
    );
  }

  void _isUserExists(AuthCurrentUser event, Emitter<AuthState> emit) async {
    final res = await _currentUser(NoParams());

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) {
        _appUserCubit.updateUserStatus(r);
        emit(AuthUserSuccess(r));
      },
    );
  }

  void _onAuthLogOut(AuthLogOut event, Emitter<AuthState> emit) async {
    final res = await _userLogout(NoParams());

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) {
        _appUserCubit.updateUserStatus(null);
        emit(AuthInitial());
      },
    );
  }
}
