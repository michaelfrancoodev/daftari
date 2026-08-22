import '../core/money.dart';
import 'enums.dart';

/// Layer two: a transaction interpreted from a capture.
///
/// Append-only. There is deliberately no update method anywhere above this
/// type: a correction inserts a replacement and points the old row at it via
/// [supersededBy]; a removal sets [voidedBy]. Both rows remain forever.
final class Entry {
  const Entry({
    required this.id,
    required this.captureId,
    required this.kind,
    required this.occurredAt,
    required this.recordedAt,
    this.amount,
    this.quantity,
    this.unit,
    this.counterparty,
    this.note,
    this.sourceSpan,
    this.uncertainFields = const <EntryField>{},
    this.supersededBy,
    this.voidedBy,
  });

  final String id;

  /// The capture this was interpreted from. Never null — every figure
  /// traces back to the sentence that produced it.
  final String captureId;

  final EntryKind kind;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final Money? amount;
  final double? quantity;
  final QuantityUnit? unit;
  final String? counterparty;
  final String? note;

  /// The exact span of the capture text that produced this row.
  final String? sourceSpan;

  /// Fields the interpreter could not read with confidence. Empty means
  /// settled.
  final Set<EntryField> uncertainFields;

  final String? supersededBy;
  final String? voidedBy;

  bool get isSettled => uncertainFields.isEmpty;

  /// Live means neither superseded nor voided — the only state that counts
  /// toward any total.
  bool get isLive => supersededBy == null && voidedBy == null;

  /// Produces a replacement that carries this entry's identity forward while
  /// marking it as corrected. Used by tests and the gap detector; production
  /// code goes through LedgerRepository.correct.
  Entry supersede(String replacementId) => Entry(
        id: id,
        captureId: captureId,
        kind: kind,
        occurredAt: occurredAt,
        recordedAt: recordedAt,
        amount: amount,
        quantity: quantity,
        unit: unit,
        counterparty: counterparty,
        note: note,
        sourceSpan: sourceSpan,
        uncertainFields: uncertainFields,
        supersededBy: replacementId,
        voidedBy: voidedBy,
      );
}
