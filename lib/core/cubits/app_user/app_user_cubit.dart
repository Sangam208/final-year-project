import 'package:bus_tracker/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserInitial());

  void updateUserStatus(User? user) =>
      emit(user == null ? AppUserInitial() : AppUserLoggedIn(user));
}
