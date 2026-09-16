// Kang Engineering Systems LLC, 2026, Copyright protection

import 'dart:async';

import 'package:camera2image/modules/local_saved/bloc/local_event.dart';
import 'package:camera2image/modules/local_saved/bloc/local_state.dart';
import 'package:camera2image/shared_models/draft_object.dart';
import 'package:camera2image/shared_models/transaction_state.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class LocalBloc extends HydratedBloc<LocalEvent, LocalState> {
  LocalBloc() : super(LocalInitial()) {
    on<LocalInitialEvent>(_onLocalInitialEvent);
    on<LocalSaveDraftEvent>(_onLocalSaveDraftEvent);
    on<LocalDisplayAllDraftsEvent>(_onLocalDisplayAllDraftsEvent);
  }

  final List<DraftObject> _drafts = <DraftObject>[];

  List<DraftObject> get drafts => List<DraftObject>.unmodifiable(_drafts);

  void _emitDrafts(Emitter<LocalState> emit) {
    emit(
      LocalSaveDraftSuccess(drafts: List<DraftObject>.unmodifiable(_drafts)),
    );
  }

  FutureOr<void> _onLocalInitialEvent(
    LocalInitialEvent event,
    Emitter<LocalState> emit,
  ) {
    if (_drafts.isEmpty) {
      return null;
    }
    _emitDrafts(emit);
  }

  FutureOr<void> _onLocalSaveDraftEvent(
    LocalSaveDraftEvent event,
    Emitter<LocalState> emit,
  ) async {
    try {
      emit(LocalProgressing());
      final bool alreadyExists = _drafts.any(
        (DraftObject draft) =>
            draft.idempotencyKey == event.draft.idempotencyKey,
      );
      if (!alreadyExists) {
        _drafts.add(event.draft);
      }
      _emitDrafts(emit);
    } catch (e) {
      emit(LocalSaveDraftFailure(error: e.toString()));
    }
  }

  @override
  LocalState? fromJson(Map<String, dynamic> json) {
    final List<dynamic>? draftsJson = json['drafts'] as List<dynamic>?;
    if (draftsJson == null) {
      return null;
    }

    _drafts
      ..clear()
      ..addAll(
        draftsJson.map(
          (dynamic item) => DraftObject.fromMap(item as Map<String, dynamic>),
        ),
      );

    for (int i = 0; i < _drafts.length; i++) {
      if (_drafts[i].state == TransactionState.uploading ||
          _drafts[i].state == TransactionState.queued) {
        _drafts[i] = _drafts[i].copyWith(state: TransactionState.draft);
      }
    }

    if (_drafts.isEmpty) {
      return null;
    }

    return LocalSaveDraftSuccess(
      drafts: List<DraftObject>.unmodifiable(_drafts),
    );
  }

  @override
  Map<String, dynamic>? toJson(LocalState state) {
    if (state is! LocalSaveDraftSuccess) {
      return null;
    }

    return <String, dynamic>{
      'drafts': state.drafts.map((DraftObject draft) => draft.toMap()).toList(),
    };
  }

  FutureOr<void> _onLocalDisplayAllDraftsEvent(
    LocalDisplayAllDraftsEvent event,
    Emitter<LocalState> emit,
  ) {
    try {
      emit(LocalDisplayAllDraftsProgressing());
      final List<DraftObject> drafts = List<DraftObject>.unmodifiable(
        _drafts
            .where((DraftObject draft) => draft.companyId == event.companyId)
            .toList(growable: false),
      );
      emit(LocalDisplayAllDraftsSuccess(drafts: drafts));
    } catch (e) {
      emit(LocalDisplayAllDraftsFailure(error: e.toString()));
    }
  }
}
