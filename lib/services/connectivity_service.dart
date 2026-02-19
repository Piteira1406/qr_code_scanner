import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service responsible for checking network connectivity.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Checks if the device is currently connected to a network.
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Helper method to check if any connectivity result indicates a connection.
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }

  /// Returns a stream of connectivity status changes.
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  /// Gets the current connectivity type as a readable string.
  Future<String> getConnectivityType() async {
    final results = await _connectivity.checkConnectivity();

    if (results.contains(ConnectivityResult.wifi)) {
      return 'Wi-Fi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'Dados Móveis';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else {
      return 'Sem Conexão';
    }
  }

  /// Disposes of any active subscriptions.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Exception thrown when there's no network connection.
class NoConnectionException implements Exception {
  final String message;
  NoConnectionException([this.message = 'Sem Conexão']);

  @override
  String toString() => message;
}
