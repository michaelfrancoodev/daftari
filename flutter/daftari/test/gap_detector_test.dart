import "package:flutter_test/flutter_test.dart";
import "package:daftari/core/money.dart";
import "package:daftari/domain/entry.dart";
import "package:daftari/domain/enums.dart";
import "package:daftari/domain/gap_detector.dart";

Entry _entry({
  required EntryKind kind,
  required DateTime occurredAt,
  String? counterparty,
  String id = "e",
}) {
  return Entry(
    id: id,
    captureId: "c",
    kind: kind,
    occurredAt: occurredAt,
    recordedAt: occurredAt,
    amount: const Money(1000),
    counterparty: counterparty,
  );
}

void main() {
  final now = DateTime(2026, 8, 20);

  group("GapDetector — ore never milled", () {
    test("flags ore bought more than 3 days ago with no milling at all", () {
      final entries = [_entry(kind: EntryKind.orePurchase, occurredAt: now.subtract(const Duration(days: 4)))];
      final gaps = GapDetector.detect(entries, now);
      expect(gaps.map((g) => g.kind), contains(GapKind.oreNeverMilled));
    });

    test("does not flag ore bought less than 3 days ago", () {
      final entries = [_entry(kind: EntryKind.orePurchase, occurredAt: now.subtract(const Duration(days: 1)))];
      expect(GapDetector.detect(entries, now), isEmpty);
    });

    test("does not flag once any milling has been recorded", () {
      final entries = [
        _entry(kind: EntryKind.orePurchase, occurredAt: now.subtract(const Duration(days: 5))),
        _entry(kind: EntryKind.milling, occurredAt: now.subtract(const Duration(days: 1)), id: "m1"),
      ];
      expect(GapDetector.detect(entries, now).map((g) => g.kind), isNot(contains(GapKind.oreNeverMilled)));
    });
  });

  group("GapDetector — milling without yield", () {
    test("flags a mill run over a day old with no yield recorded", () {
      final entries = [_entry(kind: EntryKind.milling, occurredAt: now.subtract(const Duration(days: 2)))];
      expect(GapDetector.detect(entries, now).map((g) => g.kind), contains(GapKind.millingWithoutYield));
    });

    test("does not flag once a yield exists anywhere in the entries", () {
      final entries = [
        _entry(kind: EntryKind.milling, occurredAt: now.subtract(const Duration(days: 2))),
        _entry(kind: EntryKind.goldYield, occurredAt: now, id: "y1"),
      ];
      expect(GapDetector.detect(entries, now).map((g) => g.kind), isNot(contains(GapKind.millingWithoutYield)));
    });
  });

  group("GapDetector — loan never repaid", () {
    test("flags a loan over 60 days old with no matching repayment", () {
      final entries = [_entry(kind: EntryKind.loan, occurredAt: now.subtract(const Duration(days: 61)), counterparty: "Salimu")];
      expect(GapDetector.detect(entries, now).map((g) => g.kind), contains(GapKind.loanNeverRepaid));
    });

    test("does not flag a loan under 60 days old", () {
      final entries = [_entry(kind: EntryKind.loan, occurredAt: now.subtract(const Duration(days: 10)), counterparty: "Salimu")];
      expect(GapDetector.detect(entries, now), isEmpty);
    });

    test("does not flag once that counterparty has any repayment on record", () {
      final entries = [
        _entry(kind: EntryKind.loan, occurredAt: now.subtract(const Duration(days: 90)), counterparty: "Salimu"),
        _entry(kind: EntryKind.repayment, occurredAt: now.subtract(const Duration(days: 5)), counterparty: "Salimu", id: "r1"),
      ];
      expect(GapDetector.detect(entries, now), isEmpty);
    });

    test("a loan with no counterparty at all is never flagged, since it cannot be tracked", () {
      final entries = [_entry(kind: EntryKind.loan, occurredAt: now.subtract(const Duration(days: 90)))];
      expect(GapDetector.detect(entries, now), isEmpty);
    });
  });

  test("a voided or superseded entry never raises a gap", () {
    final voided = Entry(
      id: "v1",
      captureId: "c",
      kind: EntryKind.orePurchase,
      occurredAt: now.subtract(const Duration(days: 10)),
      recordedAt: now,
      voidedBy: "void:1",
    );
    expect(GapDetector.detect([voided], now), isEmpty);
  });
}
