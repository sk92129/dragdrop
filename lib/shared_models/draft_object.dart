// Kang Engineering Systems LLC, 2026, Copyright protection

import 'package:camera2image/shared_models/transaction_state.dart';

class DraftObject {
  const DraftObject({
    required this.localId,
    required this.companyId,
    required this.vendor,
    required this.amountMinorUnits,
    required this.currency,
    required this.transactionDate,
    this.notes = '',
    required this.fileUri,
    required this.state,
    required this.idempotencyKey,
  });

  final String localId;
  final String companyId;
  final String vendor;
  final int amountMinorUnits;
  final String currency;
  final DateTime transactionDate;
  final String notes;
  final String fileUri;
  final TransactionState state;
  final String idempotencyKey;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'localId': localId,
      'companyId': companyId,
      'vendor': vendor,
      'amountMinorUnits': amountMinorUnits,
      'currency': currency,
      'transactionDate': transactionDate.toUtc().toIso8601String(),
      'notes': notes,
      'fileUri': fileUri,
      'state': state.name,
      'idempotencyKey': idempotencyKey,
    };
  }

  factory DraftObject.fromMap(Map<String, dynamic> map) {
    return DraftObject(
      localId: map['localId'] as String,
      companyId: map['companyId'] as String,
      vendor: map['vendor'] as String,
      amountMinorUnits: (map['amountMinorUnits'] as num).toInt(),
      currency: map['currency'] as String,
      transactionDate: DateTime.parse(
        map['transactionDate'] as String,
      ).toLocal(),
      notes: map['notes'] as String? ?? '',
      fileUri: map['fileUri'] as String,
      state: TransactionState.values.byName(map['state'] as String),
      idempotencyKey: map['idempotencyKey'] as String,
    );
  }

  DraftObject copyWith({
    String? localId,
    String? companyId,
    String? vendor,
    int? amountMinorUnits,
    String? currency,
    DateTime? transactionDate,
    String? notes,
    String? fileUri,
    TransactionState? state,
    String? idempotencyKey,
  }) {
    return DraftObject(
      localId: localId ?? this.localId,
      companyId: companyId ?? this.companyId,
      vendor: vendor ?? this.vendor,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      fileUri: fileUri ?? this.fileUri,
      state: state ?? this.state,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}
