import "package:flutter_test/flutter_test.dart";
import "package:daftari/core/money.dart";

void main() {
  group("Money.tryParse", () {
    test("parses a plain integer", () {
      expect(Money.tryParse("500000")?.units, 500000);
    });

    test("parses comma-grouped input", () {
      expect(Money.tryParse("500,000")?.units, 500000);
    });

    test("parses space-grouped input", () {
      expect(Money.tryParse("500 000")?.units, 500000);
    });

    test("parses dot-grouped input", () {
      expect(Money.tryParse("500.000")?.units, 500000);
    });

    test("returns null for empty input", () {
      expect(Money.tryParse(""), isNull);
    });

    test("returns null for non-numeric input", () {
      expect(Money.tryParse("laki tano"), isNull);
    });

    test("preserves a leading minus sign", () {
      expect(Money.tryParse("-500")?.units, -500);
    });

    test("returns null for a decimal amount", () {
      // Tanzanian shillings have no fractional unit in practice; a decimal
      // here is a user error to be asked about, not silently rounded.
      expect(Money.tryParse("500.5"), isNull);
    });
  });

  group("arithmetic", () {
    test("addition", () {
      expect((const Money(100) + const Money(50)).units, 150);
    });

    test("subtraction can go negative", () {
      expect((const Money(50) - const Money(100)).units, -50);
    });

    test("multiplication by an integer factor", () {
      expect((const Money(100) * 3).units, 300);
    });

    test("unary negation", () {
      expect((-const Money(100)).units, -100);
    });

    test("abs discards sign", () {
      expect((-const Money(100)).abs.units, 100);
      expect(const Money(100).abs.units, 100);
    });

    test("sumMoney folds a sequence with no intermediate double", () {
      final total = sumMoney([const Money(100), const Money(200), const Money(300)]);
      expect(total.units, 600);
    });

    test("sumMoney of an empty list is zero", () {
      expect(sumMoney(const []).units, 0);
    });
  });

  group("dividedBy", () {
    test("rounds to the nearest whole unit", () {
      expect(const Money(100).dividedBy(3)?.units, 33);
    });

    test("returns null when dividing by zero", () {
      // A batch with no yield recorded yet is an ordinary state, not an
      // error, and must never throw.
      expect(const Money(100).dividedBy(0), isNull);
    });

    test("returns null when dividing by a non-finite quantity", () {
      expect(const Money(100).dividedBy(double.nan), isNull);
    });

    test("rounds halves up", () {
      expect(const Money(5).dividedBy(2)?.units, 3);
    });
  });

  group("percentOf", () {
    test("computes a whole-number percentage", () {
      expect(const Money(63).percentOf(const Money(100)), 63);
    });

    test("returns null when the reference is zero", () {
      expect(const Money(100).percentOf(Money.zero), isNull);
    });

    test("can exceed 100 when the amount is larger than the reference", () {
      expect(const Money(150).percentOf(const Money(100)), 150);
    });
  });

  group("comparison", () {
    test("equality is by units", () {
      expect(const Money(100), equals(const Money(100)));
    });

    test("ordering operators", () {
      expect(const Money(50) < const Money(100), isTrue);
      expect(const Money(100) > const Money(50), isTrue);
      expect(const Money(100) <= const Money(100), isTrue);
      expect(const Money(100) >= const Money(100), isTrue);
    });

    test("compareTo supports sorting", () {
      final list = [const Money(300), const Money(100), const Money(200)]..sort();
      expect(list.map((m) => m.units), [100, 200, 300]);
    });
  });

  group("state predicates", () {
    test("isZero, isPositive, isNegative", () {
      expect(Money.zero.isZero, isTrue);
      expect(const Money(1).isPositive, isTrue);
      expect(const Money(-1).isNegative, isTrue);
    });
  });

  group("format", () {
    test("groups thousands for the Swahili locale", () {
      expect(const Money(500000).format(locale: "sw"), contains("500"));
    });
  });
}
