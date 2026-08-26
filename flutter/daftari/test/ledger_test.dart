import "package:flutter_test/flutter_test.dart";
import "package:daftari/core/money.dart";
import "package:daftari/domain/entry.dart";
import "package:daftari/domain/enums.dart";
import "package:daftari/domain/ledger.dart";

Entry _entry({
  required EntryKind kind,
  Money? amount,
  double? quantity,
  String captureId = "c1",
  String id = "e",
  Set<EntryField> uncertain = const {},
  String? supersededBy,
  String? voidedBy,
}) {
  return Entry(
    id: id,
    captureId: captureId,
    kind: kind,
    occurredAt: DateTime(2026, 8, 12),
    recordedAt: DateTime(2026, 8, 12),
    amount: amount,
    quantity: quantity,
    uncertainFields: uncertain,
    supersededBy: supersededBy,
    voidedBy: voidedBy,
  );
}

void main() {
  group("Ledger.summariseBatch", () {
    test("sums cost-kind entries and gold yield separately", () {
      final batch = Ledger.summariseBatch([
        _entry(kind: EntryKind.orePurchase, amount: const Money(500000), id: "1"),
        _entry(kind: EntryKind.fuel, amount: const Money(85000), id: "2"),
        _entry(kind: EntryKind.wages, amount: const Money(30000), id: "3"),
        _entry(kind: EntryKind.goldYield, quantity: 4.2, id: "4"),
      ]);
      expect(batch.costs.units, 615000);
      expect(batch.grams, 4.2);
      expect(batch.hasYield, isTrue);
      expect(batch.costPerGram?.units, 146429); // 615000 / 4.2, rounded to the nearest shilling.
    });

    test("cost per gram is null when there is no yield yet", () {
      final batch = Ledger.summariseBatch([_entry(kind: EntryKind.orePurchase, amount: const Money(500000), id: "1")]);
      expect(batch.hasYield, isFalse);
      expect(batch.costPerGram, isNull);
    });

    test("excludes sale entries from the cost total", () {
      final batch = Ledger.summariseBatch([
        _entry(kind: EntryKind.orePurchase, amount: const Money(100000), id: "1"),
        _entry(kind: EntryKind.sale, amount: const Money(900000), id: "2"),
      ]);
      expect(batch.costs.units, 100000);
    });

    test("ignores superseded and voided entries", () {
      final batch = Ledger.summariseBatch([
        _entry(kind: EntryKind.orePurchase, amount: const Money(100000), id: "1", supersededBy: "2"),
        _entry(kind: EntryKind.orePurchase, amount: const Money(200000), id: "2"),
      ]);
      expect(batch.costs.units, 200000);
    });
  });

  group("Ledger.summariseDay", () {
    test("separates money in from money out", () {
      final day = Ledger.summariseDay([
        _entry(kind: EntryKind.sale, amount: const Money(882000), id: "1"),
        _entry(kind: EntryKind.repayment, amount: const Money(50000), id: "2"),
        _entry(kind: EntryKind.orePurchase, amount: const Money(500000), id: "3"),
        _entry(kind: EntryKind.fuel, amount: const Money(85000), id: "4"),
      ]);
      expect(day.moneyIn.units, 932000);
      expect(day.moneyOut.units, 585000);
    });

    test("completeness is 100 for an empty day", () {
      expect(Ledger.summariseDay(const []).completeness, 100);
    });

    test("completeness counts settled vs. incomplete entries", () {
      final day = Ledger.summariseDay([
        _entry(kind: EntryKind.orePurchase, amount: const Money(1), id: "1"),
        _entry(kind: EntryKind.orePurchase, amount: null, id: "2", uncertain: {EntryField.amount}),
        _entry(kind: EntryKind.orePurchase, amount: const Money(1), id: "3"),
        _entry(kind: EntryKind.orePurchase, amount: const Money(1), id: "4"),
      ]);
      expect(day.entryCount, 4);
      expect(day.incompleteCount, 1);
      expect(day.completeness, 75);
    });
  });

  group("Ledger.groupByCapture", () {
    test("groups live entries by capture, preserving order", () {
      final grouped = Ledger.groupByCapture([
        _entry(kind: EntryKind.orePurchase, captureId: "cap1", id: "1"),
        _entry(kind: EntryKind.fuel, captureId: "cap2", id: "2"),
        _entry(kind: EntryKind.wages, captureId: "cap1", id: "3"),
      ]);
      expect(grouped.keys, containsAll(["cap1", "cap2"]));
      expect(grouped["cap1"]!.map((e) => e.id), ["1", "3"]);
    });

    test("excludes voided entries from every group", () {
      final grouped = Ledger.groupByCapture([
        _entry(kind: EntryKind.orePurchase, captureId: "cap1", id: "1", voidedBy: "void:1"),
      ]);
      expect(grouped, isEmpty);
    });
  });

  group("Ledger.groupByDay", () {
    test("groups entries by calendar day, most recent first", () {
      final grouped = Ledger.groupByDay([
        _entry(kind: EntryKind.orePurchase, id: "1"), // 2026-08-12
        _entry(kind: EntryKind.fuel, id: "2"),
      ]);
      expect(grouped.keys.single, DateTime(2026, 8, 12));
      expect(grouped[DateTime(2026, 8, 12)]!.length, 2);
    });

    test("excludes voided entries", () {
      final grouped = Ledger.groupByDay([
        _entry(kind: EntryKind.orePurchase, id: "1", voidedBy: "void:1"),
      ]);
      expect(grouped, isEmpty);
    });

    test("orders multiple days newest first", () {
      final grouped = Ledger.groupByDay([
        Entry(
          id: "old",
          captureId: "c1",
          kind: EntryKind.orePurchase,
          occurredAt: DateTime(2026, 8, 1),
          recordedAt: DateTime(2026, 8, 1),
          amount: const Money(1),
        ),
        Entry(
          id: "new",
          captureId: "c1",
          kind: EntryKind.orePurchase,
          occurredAt: DateTime(2026, 8, 10),
          recordedAt: DateTime(2026, 8, 10),
          amount: const Money(1),
        ),
      ]);
      expect(grouped.keys.toList(), [DateTime(2026, 8, 10), DateTime(2026, 8, 1)]);
    });
  });

  group("Ledger.valueOf", () {
    test("multiplies a per-gram figure by grams and rounds", () {
      expect(Ledger.valueOf(perGram: const Money(146429), grams: 4.2).units, 615002);
    });
  });

  group("Ledger.assessMargin — cost vs. a buyer's offer only", () {
    test("computes profit as offer minus the batch's own cost, nothing else", () {
      final assessment = Ledger.assessMargin(offerPerGram: const Money(210000), costPerGram: const Money(146429), grams: 4.2);
      expect(assessment.costTotal.units, 615002);
      expect(assessment.offeredTotal.units, 882000);
      expect(assessment.profit.units, 266998);
      expect(assessment.profitPerGram.units, 63571);
      expect(assessment.isProfitable, isTrue);
    });

    test("a loss is reported plainly, never hidden", () {
      final assessment = Ledger.assessMargin(offerPerGram: const Money(100000), costPerGram: const Money(146429), grams: 4.2);
      expect(assessment.isProfitable, isFalse);
      expect(assessment.profit.isNegative, isTrue);
    });

    test("never compares against anything but the two numbers given", () {
      // This is the whole point of the rewrite: no reference price, no
      // personal average, no external lookup of any kind — just the two
      // figures the user typed in themselves.
      final assessment = Ledger.assessMargin(offerPerGram: const Money(200000), costPerGram: const Money(200000), grams: 1);
      expect(assessment.profit, Money.zero);
      expect(assessment.isProfitable, isTrue); // Break-even counts as non-negative.
    });
  });
}
