// Kang Engineering Systems LLC, 2026, Copyright protection

enum TransactionState {
  draft,
  queued,
  uploading,
  processing,
  failed,
  needsReview,
  confirmed,
}

extension TransactionStateExtension on TransactionState {
  /// User-facing label for UI.
  String get displayName => switch (this) {
    TransactionState.draft => 'Draft',
    TransactionState.queued => 'Queued',
    TransactionState.uploading => 'Uploading',
    TransactionState.processing => 'Processing',
    TransactionState.failed => 'Failed',
    TransactionState.needsReview => 'Needs Review',
    TransactionState.confirmed => 'Confirmed',
  };

  /// Stable value for local storage (e.g. `draft`, `queued`).
  String get storageKey => name;

  /// Receipts saved locally and not yet fully uploaded/confirmed.
  bool get isPending =>
      this == TransactionState.draft ||
      this == TransactionState.queued ||
      this == TransactionState.uploading ||
      this == TransactionState.processing ||
      this == TransactionState.needsReview;

  /// Receipts that have reached the server-side upload flow.
  bool get isUploaded =>
      this == TransactionState.processing ||
      this == TransactionState.failed ||
      this == TransactionState.confirmed ||
      this == TransactionState.needsReview;

  bool get isTerminal =>
      this == TransactionState.failed || this == TransactionState.confirmed;

  static TransactionState fromStorageKey(String value) {
    return TransactionState.values.firstWhere(
      (TransactionState state) => state.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unknown transaction state',
      ),
    );
  }

  static TransactionState? tryParse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final TransactionState state in TransactionState.values) {
      if (state.name == value) {
        return state;
      }
    }
    return null;
  }
}
