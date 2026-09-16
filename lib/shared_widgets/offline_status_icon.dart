// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/services/connectivity/connectivity_cubit.dart';
import 'package:camera2image/shared_widgets/qa_semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-bar action that appears only while the device is offline.
class OfflineStatusIcon extends StatelessWidget {
  const OfflineStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (BuildContext context, bool isConnected) {
        if (isConnected) {
          return const SizedBox.shrink();
        }
        return myWidget(
          id: 'app.offline_status_icon',
          label: 'No internet connection',
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Tooltip(
              message: 'No internet connection',
              child: Icon(Icons.cloud_off),
            ),
          ),
        );
      },
    );
  }
}

List<Widget> withOfflineStatusIcon({List<Widget> actions = const <Widget>[]}) {
  return <Widget>[...actions, const OfflineStatusIcon()];
}
