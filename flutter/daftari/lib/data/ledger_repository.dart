import "package:uuid/uuid.dart";
import "../domain/capture.dart";
import "../domain/entry.dart";
import "../domain/enums.dart";
import "../domain/gap_detector.dart";
import "../domain/interpreter.dart";
import "../core/money.dart";
import "database.dart";
import "database_mappers.dart";

const _uuid = Uuid();

/// A gap the system noticed on its own, joined with the entry that raised
/// it — everything the Inbox screen needs to render one card.
final class GapWithEntry {
  const GapWithEntry({required this.gap, required this.entry});

  final Gap gap;
  final Entry entry;
}

/// What committing a spoken or typed sentence produces.
final class CommitResult {
  const CommitResult({required this.capture, required this.entries});

  final Capture capture;
  final List<Entry> entries;

  /// True when every transaction found was read with confidence — the
  /// review card can then be skipped in favour of the three-second
  /// confirmation sheet.
  bool get allSettled => entries.every((Entry e) => e.isSettled);
}

/// The single place that wires the pure domain logic (`Interpreter`,
/// `Ledger`, `GapDetector`) to the database. Screens depend on this, never
/// on `AppDatabase` directly, so the append-only rules in `database.dart`
/// stay enforced in exactly one place.
class LedgerRepository {
  LedgerRepository(this._db);

  final AppDatabase _db;

  /// Splits an utterance into drafts. Pure and instant — works with the
  /// aeroplane-mode switch on, per Rule #2.
  List<DraftEntry> interpret(String utterance) => Interpreter.interpret(utterance);

  /// Writes a capture and every draft entry found inside it, in one batch.
  /// Nothing is written until the caller has shown the review card (or
  /// skipped it, when everything was already settled) and the user agreed.
  Future<CommitResult> commit({
    required String verbatimText,
    required CaptureSource source,
    required String languageCode,
    required List<DraftEntry> drafts,
    String? audioPath,
    DateTime? occurredAt,
  }) async {
    final DateTime now = occurredAt ?? DateTime.now();
    final Capture capture = Capture(
      id: _uuid.v4(),
      occurredAt: now,
      verbatimText: verbatimText,
      source: source,
      languageCode: languageCode,
      audioPath: audioPath,
    );

    final List<Entry> entries = drafts
        .map(
          (DraftEntry d) => Entry(
            id: _uuid.v4(),
            captureId: capture.id,
            kind: d.kind,
            occurredAt: now,
            recordedAt: DateTime.now(),
            amount: d.amount,
            quantity: d.quantity,
            counterparty: d.counterparty,
            note: d.note,
            sourceSpan: d.sourceSpan,
            uncertainFields: d.uncertainFields,
          ),
        )
        .toList(growable: false);

    await _db.insertCapture(capture.toCompanion());
    if (entries.isNotEmpty) {
      await _db.insertEntries(entries.map((Entry e) => e.toCompanion()).toList(growable: false));
    }

    return CommitResult(capture: capture, entries: entries);
  }

  /// Answers a question raised by the Inbox: writes a replacement entry
  /// with the missing field filled in and points the old row at it. The
  /// old row's values are never touched, only its `supersededBy` pointer.
  Future<void> resolveField(
    Entry entry, {
    Money? amount,
    double? quantity,
    String? counterparty,
  }) async {
    final Set<EntryField> remaining = Set<EntryField>.from(entry.uncertainFields);
    if (amount != null) remaining.remove(EntryField.amount);
    if (quantity != null) remaining.remove(EntryField.quantity);
    if (counterparty != null) remaining.remove(EntryField.counterparty);

    final Entry replacement = Entry(
      id: _uuid.v4(),
      captureId: entry.captureId,
      kind: entry.kind,
      occurredAt: entry.occurredAt,
      recordedAt: DateTime.now(),
      amount: amount ?? entry.amount,
      quantity: quantity ?? entry.quantity,
      unit: entry.unit,
      counterparty: counterparty ?? entry.counterparty,
      note: entry.note,
      sourceSpan: entry.sourceSpan,
      uncertainFields: remaining,
    );

    await _db.correctEntry(replacement: replacement.toCompanion(), supersededId: entry.id);
  }

  /// A void marker is written; the row remains and stops counting.
  Future<void> voidEntry(String entryId) => _db.voidEntryRow(entryId);

  Stream<List<Entry>> watchToday() => _db.watchEntriesForDay(DateTime.now());

  Stream<List<Entry>> watchUncertain() => _db.watchUncertain();

  /// A single past (or present) day's live entries — used both by the Day
  /// Report screen when opened for a date other than today, and by Home's
  /// "recent reports" list.
  Future<List<Entry>> entriesForDay(DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    return _db.entriesBetween(start, end);
  }

  /// Every live entry from the last [days] calendar days, inclusive of
  /// today — a single query the caller groups by day (see
  /// `Ledger.groupByDay`), rather than one query per day.
  Future<List<Entry>> entriesForRecentDays({int days = 7}) {
    final DateTime todayStart = DateTime.now();
    final DateTime start = DateTime(todayStart.year, todayStart.month, todayStart.day).subtract(Duration(days: days - 1));
    final DateTime end = DateTime(todayStart.year, todayStart.month, todayStart.day).add(const Duration(days: 1));
    return _db.entriesBetween(start, end);
  }

  Future<List<Entry>> entriesForMonth(DateTime month) {
    final DateTime start = DateTime(month.year, month.month, 1);
    final DateTime end = DateTime(month.year, month.month + 1, 1);
    return _db.entriesBetween(start, end);
  }

  Future<List<Entry>> entriesForCapture(String captureId) => _db.entriesForCapture(captureId);

  Future<Capture?> captureById(String captureId) => _db.captureById(captureId);

  /// Gaps the system noticed on its own, each joined with the entry that
  /// raised it. Looks back 90 days, which comfortably covers the 60-day
  /// loan patience window in `GapDetector`.
  Future<List<GapWithEntry>> detectGaps() async {
    final DateTime now = DateTime.now();
    final List<Entry> entries = await _db.entriesBetween(now.subtract(const Duration(days: 90)), now.add(const Duration(days: 1)));
    final Map<String, Entry> byId = <String, Entry>{for (final Entry e in entries) e.id: e};

    final List<GapWithEntry> results = <GapWithEntry>[];
    for (final Gap gap in GapDetector.detect(entries, now)) {
      final Entry? entry = byId[gap.entryId];
      if (entry != null) results.add(GapWithEntry(gap: gap, entry: entry));
    }
    return results;
  }
}
