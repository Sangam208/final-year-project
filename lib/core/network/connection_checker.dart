import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract interface class ConnectionChecker {
  Future<bool> get isConnected;
}

class ConnectionCheckerImplementation implements ConnectionChecker {
  final InternetConnection _internetConnection;
  ConnectionCheckerImplementation(this._internetConnection);

  @override
  Future<bool> get isConnected async =>
      await _internetConnection.hasInternetAccess;
}
