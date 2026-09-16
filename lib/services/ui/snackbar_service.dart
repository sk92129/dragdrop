// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/shared_widgets/qa_semantics.dart';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, info }

class SnackbarService {
  SnackbarService._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String message,
    SnackbarType type = SnackbarType.info,
  }) {
    final ScaffoldMessengerState? messenger = messengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: myWidgetKey('snackbar.${type.name}'),
          content: myWidget(
            id: 'snackbar.${type.name}.message',
            child: Text(message),
          ),
          backgroundColor: switch (type) {
            SnackbarType.success => Colors.green.shade700,
            SnackbarType.error => Colors.red.shade700,
            SnackbarType.info => null,
          },
        ),
      );
  }
}
