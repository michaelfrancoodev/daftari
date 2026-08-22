import "package:flutter_test/flutter_test.dart";
import "package:daftari/core/money.dart";
import "package:daftari/domain/entry.dart";
import "package:daftari/domain/enums.dart";

Entry _entry({
  String id = "e1",
  Set<EntryField> uncertain = const {},
  String? supersededBy,
  String? voidedBy,
}) {
  return Entry(
    id: id,
    captureId: "c1",
    kind: EntryKind.sale,
    occurredAt: DateTime(2026, 8, 12),
    recordedAt: DateTime(2026, 8, 12),
    amount: const Money(100000),
    uncertainFields: uncertain,
    supersededBy: supersededBy,
    voidedBy: voidedBy,
  );
}

void main() {
  group("Entry.isSettled", () {
    test("true when no field is uncertain", () {
      expect(_entry().isSettled, isTrue);
    });

    test("false when a field is uncertain", () {
      expect(_entry(uncertain: {EntryField.amount}).isSettled, isFalse);
    });
  });

  group("Entry.isLive — append-only lifecycle", () {
    test("a fresh entry is live", () {
      expect(_entry().isLive, isTrue);
    });

    test("a superseded entry is not live", () {
      expect(_entry(supersededBy: "e2").isLive, isFalse);
    });

    test("a voided entry is not live", () {
      expect(_entry(voidedBy: "void:1").isLive, isFalse);
    });
  });

  group("Entry.supersede", () {
    test("carries the same identity and values forward", () {
      final original = _entry();
      final superseded = original.supersede("e2");
      expect(superseded.id, original.id);
      expect(superseded.amount, original.amount);
      expect(superseded.supersededBy, "e2");
      expect(superseded.isLive, isFalse);
    });

    test("does not mutate the fields of the original", () {
      final original = _entry();
      original.supersede("e2");
      // The original Entry instance is immutable — a new object is
      // returned. This is the mechanism that keeps `database.dart`
      // insert-only: no field on a row is ever changed in place except a
      // lifecycle pointer.
      expect(original.supersededBy, isNull);
    });
  });
}
