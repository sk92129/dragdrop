// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/shared_models/draft_object.dart';

abstract class LocalEvent {}

class LocalInitialEvent extends LocalEvent {}

class LocalSaveDraftEvent extends LocalEvent {
  LocalSaveDraftEvent({required this.draft});

  final DraftObject draft;
}

class LocalDisplayAllDraftsEvent extends LocalEvent {
  LocalDisplayAllDraftsEvent({required this.companyId});

  final String companyId;
}
