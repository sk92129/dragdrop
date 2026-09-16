// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:async';

import 'package:camera2image/services/connectivity/connectivity_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// `true` when the device reports a network interface.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit({ConnectivityService? service})
      : _service = service ?? ConnectivityService.instance,
        super((service ?? ConnectivityService.instance).isConnected) {
    _subscription = _service.connected.listen(emit);
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
