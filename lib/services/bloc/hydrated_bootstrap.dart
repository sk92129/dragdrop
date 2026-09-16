// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initializeHydratedBloc() async {
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );
}
