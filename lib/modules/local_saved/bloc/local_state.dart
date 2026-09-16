// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/shared_models/draft_object.dart';

class LocalState {
  const LocalState();
}

class LocalInitial extends LocalState {}

class LocalProgressing extends LocalState {}

class LocalSaveDraftSuccess extends LocalState {
  const LocalSaveDraftSuccess({required this.drafts});

  final List<DraftObject> drafts;
}

class LocalSaveDraftFailure extends LocalState {
  LocalSaveDraftFailure({required this.error});
  final String error;
}

class LocalDisplayAllDraftsProgressing extends LocalState {}

class LocalDisplayAllDraftsSuccess extends LocalState {
  const LocalDisplayAllDraftsSuccess({required this.drafts});
  final List<DraftObject> drafts;
}

class LocalDisplayAllDraftsFailure extends LocalState {
  const LocalDisplayAllDraftsFailure({required this.error});
  final String error;
}
