import 'dart:async';

import 'package:bus_tracker/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserInitial());

  void updateUserStatus(User? user) =>
      emit(user == null ? AppUserInitial() : AppUserLoggedIn(user));

  final StreamController<void> _logoutRequestedController =
      StreamController<void>.broadcast();

  void requestLogout() => _logoutRequestedController.add(null);

  Stream<void> get logoutRequested => _logoutRequestedController.stream;

  @override
  Future<void> close() async {
    await _logoutRequestedController.close();
    super.close();
  }
}
