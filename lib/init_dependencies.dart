import 'package:bus_tracker/core/config/secrets.dart';
import 'package:bus_tracker/core/cubits/app_user/app_user_cubit.dart';
import 'package:bus_tracker/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:bus_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bus_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:bus_tracker/features/auth/domain/usecases/current_user.dart';
import 'package:bus_tracker/features/auth/domain/usecases/user_logout.dart';
import 'package:bus_tracker/features/auth/domain/usecases/user_send_otp.dart';
import 'package:bus_tracker/features/auth/domain/usecases/user_verify_otp.dart';
import 'package:bus_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bus_tracker/features/map/data/datasources/map_remote_data_source.dart';
import 'package:bus_tracker/features/map/data/repositories/map_repository_impl.dart';
import 'package:bus_tracker/features/map/domain/repositories/map_repository.dart';
import 'package:bus_tracker/features/map/presentation/cubit/map/map_cubit.dart';
import 'package:bus_tracker/features/map/presentation/cubit/user_location/user_location_cubit.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final serviceLocator = GetIt.instance;

Future<void> initDepedencies() async {
  final supabase = await Supabase.initialize(
    url: projectURI,
    publishableKey: anonKey,
  );

  serviceLocator
    ..registerLazySingleton(
      () => supabase.client,
    )
    ..registerLazySingleton(
      () => AppUserCubit(),
    )
    ..registerLazySingleton(
      () => UserLocationCubit(),
    );

  _initAuth();
  _initMap();
}

void _initAuth() {
  serviceLocator
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserSendOTP(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserVerifyOtp(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => CurrentUser(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserLogout(
        serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => AuthBloc(
        userSendOTP: serviceLocator(),
        userVerifyOtp: serviceLocator(),
        appUserCubit: serviceLocator(),
        currentUser: serviceLocator(),
        userLogOut: serviceLocator(),
      ),
    );
}

void _initMap() {
  serviceLocator
    ..registerFactory(
      () => Dio(),
    )
    ..registerFactory<MapRemoteDataSource>(
      () => MapRemoteDataSourceImpl(
        serviceLocator(),
      ),
    )
    ..registerFactory<MapRepository>(
      () => MapRepositoryImpl(
        serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => MapCubit(
        mapRepository: serviceLocator(),
        userLocationCubit: serviceLocator(),
      ),
    );
}
