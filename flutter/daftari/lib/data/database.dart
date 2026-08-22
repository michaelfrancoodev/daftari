import "dart:io";
import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:uuid/uuid.dart";
import "../domain/enums.dart";
import "database_mappers.dart";

part "database.g.dart";

const _uuid = Uuid();

/// Layer 1 — what the user actually said or typed.
///
/// Mirrors `domain/capture.dart` exactly. `syncedAt` is the only column any
/// row in this table ever has updated after insert; everything else is
/// write-once. The table is named `CaptureRows` (not `Captures`) purely to
/// keep Drift's generated data class (`CaptureRow`) from colliding with the
/// plain `Capture` domain class in `domain/capture.dart` — the two are
/// intentionally kept separate, with `database_mappers.dart` as the only
/// bridge between them.
class CaptureRows extends Table {
  TextColumn get id => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get verbatimText => text()();
  TextColumn get source => textEnum<CaptureSource>()();
  TextColumn get languageCode => text()();
  TextColumn get audioPath => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Layer 2 — a transaction interpreted from a capture.
///
/// Mirrors `domain/entry.dart`. There is deliberately no general UPDATE or
/// DELETE anywhere in this file. The only two columns ever written after
/// insert are [supersededBy] and [voidedBy] — the lifecycle pointers a
/// correction or a removal sets. Definition-of-Done check G3 ("grep the data
/// layer for UPDATE/DELETE: only the two lifecycle pointers may appear")
/// exists specifically to keep this file honest as it grows.
class EntryRows extends Table {
  TextColumn get id => text()();
  TextColumn get captureId => text().references(CaptureRows, #id)();
  TextColumn get kind => textEnum<EntryKind>()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime()();

  /// Money, stored as whole minor units. Never a REAL column — Rule #6.
  IntColumn get amountMinorUnits => integer().nullable()();

  RealColumn get quantity => real().nullable()();
  TextColumn get unit => textEnum<QuantityUnit>().nullable()();
  TextColumn get counterparty => text().nullable()();
  TextColumn get note => text().nullable()();

  /// The exact span of the capture's verbatim text this row was read from.
  TextColumn get sourceSpan => text().nullable()();

  /// Comma-joined `EntryField` names. Empty string means fully settled.
  TextColumn get uncertainFields => text().withDefault(const Constant(""))();

  /// Lifecycle pointers. Set exactly once, never cleared.
  TextColumn get supersededBy => text().nullable()();
  TextColumn get voidedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CaptureRows, EntryRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------
  // Captures — write once, read many.
  // ---------------------------------------------------------------------

  Future<Capture> insertCapture(CaptureRowsCompanion companion) async {
    await into(captureRows).insert(companion);
    final row = await (select(captureRows)..where((t) => t.id.equals(companion.id.value))).getSingle();
    return row.toDomain();
  }

  Future<Capture?> captureById(String id) async {
    final row = await (select(captureRows)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  /// The verbatim sentence never changes; only whether it has synced does.
  Future<void> markCaptureSynced(String id, DateTime syncedAt) {
    return (update(captureRows)..where((t) => t.id.equals(id))).write(CaptureRowsCompanion(syncedAt: Value(syncedAt)));
  }

  // ---------------------------------------------------------------------
  // Entries — append-only ledger.
  // ---------------------------------------------------------------------

  Future<void> insertEntries(List<EntryRowsCompanion> rows) async {
    await batch((b) => b.insertAll(entryRows, rows));
  }

  /// A correction: insert the replacement, then point the superseded row at
  /// it. The old row's values are never touched — only its pointer.
  Future<void> correctEntry({
    required EntryRowsCompanion replacement,
    required String supersededId,
  }) async {
    await batch((b) {
      b.insert(entryRows, replacement);
      b.update(
        entryRows,
        EntryRowsCompanion(supersededBy: Value(replacement.id.value)),
        where: (t) => t.id.equals(supersededId),
      );
    });
  }

  /// A removal: the row remains and simply stops counting toward any total.
  Future<void> voidEntryRow(String id) async {
    final marker = "void:${_uuid.v4()}";
    await (update(entryRows)..where((t) => t.id.equals(id))).write(EntryRowsCompanion(voidedBy: Value(marker)));
  }

  Stream<List<Entry>> watchEntriesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(entryRows)
          ..where((t) => t.occurredAt.isBiggerOrEqualValue(start) & t.occurredAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList(growable: false));
  }

  Stream<List<Entry>> watchUncertain() {
    return (select(entryRows)
          ..where((t) => t.uncertainFields.equals("").not() & t.supersededBy.isNull() & t.voidedBy.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList(growable: false));
  }

  Future<List<Entry>> entriesBetween(DateTime start, DateTime end) async {
    final rows = await (select(entryRows)
          ..where((t) => t.occurredAt.isBiggerOrEqualValue(start) & t.occurredAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .get();
    return rows.map((r) => r.toDomain()).toList(growable: false);
  }

  Future<List<Entry>> entriesForCapture(String captureId) async {
    final rows = await (select(entryRows)
          ..where((t) => t.captureId.equals(captureId))
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();
    return rows.map((r) => r.toDomain()).toList(growable: false);
  }

  // ---------------------------------------------------------------------
  // Price cache: intentionally absent.
  //
  // DAFTARI does not fetch, cache, or display any external "gold price".
  // Gold varies in purity, grade, and buyer, so a single published figure
  // would misrepresent what any individual miner actually receives — see
  // domain/ledger.dart's `MarginAssessment` for what replaced this.
  // ---------------------------------------------------------------------
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, "daftari.sqlite"));
    return NativeDatabase.createInBackground(file);
  });
}
