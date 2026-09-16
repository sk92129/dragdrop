// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/main.dart';
import 'package:camera2image/modules/file_picker/ui/file_picker_screen.dart';
import 'package:camera2image/modules/local_saved/ui/pending_screen.dart';
import 'package:camera2image/modules/capture/ui/save_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRoutes { home, save, pending, filePicker }

AppRoutes? findRoute(String url) {
  switch (url) {
    case "/":
      return AppRoutes.home;
    case "/save":
      return AppRoutes.save;
    case "/pending":
      return AppRoutes.pending;
    case "/filePicker":
      return AppRoutes.filePicker;
    default:
      return null;
  }
}

extension AppRoutesExtension on AppRoutes {
  String get toName => name;
}

extension AppRouteExtension on AppRoutes {
  String get toPath {
    switch (this) {
      case AppRoutes.home:
        return '/';
      case AppRoutes.save:
        return '/save';
      case AppRoutes.pending:
        return '/pending';
      case AppRoutes.filePicker:
        return '/filePicker';
    }
  }
}

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      name: AppRoutes.home.name,
      path: AppRoutes.home.toPath,
      builder: (BuildContext context, GoRouterState state) {
        return const MyHomePage(title: 'Receipt Capture');
      },
    ),
    GoRoute(
      name: AppRoutes.filePicker.name,
      path: AppRoutes.filePicker.toPath,
      builder: (BuildContext context, GoRouterState state) {
        return const FilePickerScreen();
      },
    ),
    GoRoute(
      name: AppRoutes.save.name,
      path: AppRoutes.save.toPath,
      builder: (BuildContext context, GoRouterState state) {
        final String? imagePath = state.extra as String?;
        return SaveScreen(imagePath: imagePath);
      },
    ),
    GoRoute(
      name: AppRoutes.pending.name,
      path: AppRoutes.pending.toPath,
      builder: (BuildContext context, GoRouterState state) {
        return const PendingScreen();
      },
    ),
  ],
);
