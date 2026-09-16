// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class OfflineException implements Exception {
  const OfflineException([this.message = 'Device is offline.']);

  final String message;

  @override
  String toString() => message;
}

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectedController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool _initialized = false;

  bool get isConnected => _isConnected;

  Stream<bool> get connected => _connectedController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final List<ConnectivityResult> initial =
        await _connectivity.checkConnectivity();
    _setConnected(_hasNetwork(initial));
    _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _setConnected(_hasNetwork(results));
      },
    );
  }

  Future<bool> checkConnected() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    final bool online = _hasNetwork(results);
    _setConnected(online);
    return online;
  }

  Future<void> waitUntilConnected() async {
    if (await checkConnected()) {
      return;
    }
    await connected.firstWhere((bool isConnected) => isConnected);
  }

  bool isNetworkError(Object error) {
    if (error is OfflineException) {
      return true;
    }
    final String message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('network-request-failed') ||
        message.contains('network_error') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('offline');
  }

  void _setConnected(bool value) {
    if (_isConnected == value) {
      return;
    }
    _isConnected = value;
    debugPrint('Connectivity: ${value ? 'online' : 'offline'}');
    if (!_connectedController.isClosed) {
      _connectedController.add(value);
    }
  }

  static bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );
  }
}
