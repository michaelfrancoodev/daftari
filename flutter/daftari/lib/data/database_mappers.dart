import "package:drift/drift.dart" show Value;
import "../core/money.dart";
import "../domain/capture.dart";
import "../domain/entry.dart";
import "../domain/enums.dart";
import "database.dart";

/// Converts between the pure `domain/` classes and Drift's generated row
/// classes. Nothing outside this file and `database.dart` should ever import
/// a Drift row type directly — the rest of the app speaks `Capture` and
/// `Entry` only.

String _encodeFields(Set<EntryField> fields) => fields.map((f) => f.name).join(",");

Set<EntryField> _decodeFields(String encoded) {
  if (encoded.isEmpty) return const <EntryField>{};
  return encoded.split(",").map(EntryField.values.byName).toSet();
}

extension CaptureRowMapper on CaptureRow {
  Capture toDomain() => Capture(
        id: id,
        occurredAt: occurredAt,
        verbatimText: verbatimText,
        source: source,
        languageCode: languageCode,
        audioPath: audioPath,
        syncedAt: syncedAt,
      );
}

extension CaptureCompanionMapper on Capture {
  CaptureRowsCompanion toCompanion() => CaptureRowsCompanion.insert(
        id: id,
        occurredAt: occurredAt,
        verbatimText: verbatimText,
        source: source,
        languageCode: languageCode,
        audioPath: Value(audioPath),
        syncedAt: Value(syncedAt),
      );
}

extension EntryRowMapper on EntryRow {
  Entry toDomain() => Entry(
        id: id,
        captureId: captureId,
        kind: kind,
        occurredAt: occurredAt,
        recordedAt: recordedAt,
        amount: amountMinorUnits == null ? null : Money(amountMinorUnits!),
        quantity: quantity,
        unit: unit,
        counterparty: counterparty,
        note: note,
        sourceSpan: sourceSpan,
        uncertainFields: _decodeFields(uncertainFields),
        supersededBy: supersededBy,
        voidedBy: voidedBy,
      );
}

extension EntryCompanionMapper on Entry {
  EntryRowsCompanion toCompanion() => EntryRowsCompanion.insert(
        id: id,
        captureId: captureId,
        kind: kind,
        occurredAt: occurredAt,
        recordedAt: recordedAt,
        amountMinorUnits: Value(amount?.units),
        quantity: Value(quantity),
        unit: Value(unit),
        counterparty: Value(counterparty),
        note: Value(note),
        sourceSpan: Value(sourceSpan),
        uncertainFields: Value(_encodeFields(uncertainFields)),
        supersededBy: Value(supersededBy),
        voidedBy: Value(voidedBy),
      );
}
