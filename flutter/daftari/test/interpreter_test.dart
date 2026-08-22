import "package:flutter_test/flutter_test.dart";
import "package:daftari/domain/enums.dart";
import "package:daftari/domain/interpreter.dart";

void main() {
  group("Interpreter.interpret — Master Specification test B1", () {
    // "3 transactions, correct kinds, correct amounts, Michael and Salimu
    // identified" — Definition of Done, test B1.
    const sentence =
        "Nimempatia Michael elfu tano ya kufrisha ponchi, na nikanunua umeme wa elfu ishirini na tano, na nimekopesha laki mbili kwa Salimu";
    final drafts = Interpreter.interpret(sentence);

    test("finds exactly three transactions", () {
      expect(drafts.length, 3);
    });

    test("first clause is wages, paid to Michael, for 5,000", () {
      expect(drafts[0].kind, EntryKind.wages);
      expect(drafts[0].counterparty, "Michael");
      expect(drafts[0].amount?.units, 5000);
    });

    test("second clause is fuel, for 25,000", () {
      expect(drafts[1].kind, EntryKind.fuel);
      expect(drafts[1].amount?.units, 25000);
    });

    test("third clause is a loan to Salimu, for 200,000", () {
      expect(drafts[2].kind, EntryKind.loan);
      expect(drafts[2].counterparty, "Salimu");
      expect(drafts[2].amount?.units, 200000);
    });

    test("every field on every draft is settled", () {
      expect(drafts.every((d) => d.isSettled), isTrue);
    });
  });

  group("Interpreter.interpret — test B5, an unnamed loan", () {
    test("a loan with no named party is flagged, not guessed", () {
      final drafts = Interpreter.interpret("nimekopesha mtu laki mbili");
      expect(drafts, hasLength(1));
      expect(drafts.first.kind, EntryKind.loan);
      expect(drafts.first.counterparty, isNull);
      expect(drafts.first.uncertainFields, contains(EntryField.counterparty));
    });
  });

  group("Interpreter.interpret — test B6, nothing to understand", () {
    test("an empty result comes back honestly rather than guessing", () {
      final drafts = Interpreter.interpret("habari ya asubuhi");
      expect(drafts, isEmpty);
    });
  });

  group("Interpreter.interpret — gold yield with a clear quantity", () {
    test("reads grams stated as a decimal number", () {
      final drafts = Interpreter.interpret("nimepata 4.2 gramu");
      expect(drafts, hasLength(1));
      expect(drafts.first.kind, EntryKind.goldYield);
      expect(drafts.first.quantity, 4.2);
      expect(drafts.first.isSettled, isTrue);
    });
  });

  group("Interpreter.interpret — gold yield with an ambiguous quantity", () {
    test("a quantity that cannot be read becomes a question, not a guess", () {
      // Master Specification test B4: "point moja therusi saba" must not
      // resolve to a plausible-looking number.
      final drafts = Interpreter.interpret("nimepata point moja therusi saba");
      expect(drafts, hasLength(1));
      expect(drafts.first.kind, EntryKind.goldYield);
      expect(drafts.first.uncertainFields, contains(EntryField.quantity));
    });
  });

  group("Interpreter.interpret — ore purchase", () {
    test("recognises magunia as ore", () {
      final drafts = Interpreter.interpret("nimenunua magunia matatu kwa Juma elfu hamsini");
      expect(drafts, hasLength(1));
      expect(drafts.first.kind, EntryKind.orePurchase);
      expect(drafts.first.counterparty, "Juma");
      expect(drafts.first.amount?.units, 50000);
    });
  });

  group("Interpreter.interpret — a sale", () {
    test("recognises nimeuza as a sale", () {
      final drafts = Interpreter.interpret("nimeuza dhahabu kwa laki nane");
      expect(drafts, hasLength(1));
      expect(drafts.first.kind, EntryKind.sale);
      expect(drafts.first.amount?.units, 800000);
    });
  });

  group("Interpreter.interpret — a repayment", () {
    test("recognises marejesho as a repayment", () {
      final drafts = Interpreter.interpret("nimemrudishia Kondo elfu ishirini");
      expect(drafts, hasLength(1));
      expect(drafts.first.kind, EntryKind.repayment);
      expect(drafts.first.counterparty, "Kondo");
    });

    test("repayment is preferred over loan when both stems could apply", () {
      // "nimemrudishia" must be tested before "nimekopa" — order matters,
      // per the comment in Interpreter._verbs.
      final drafts = Interpreter.interpret("nimemrudishia Salimu elfu kumi");
      expect(drafts.first.kind, EntryKind.repayment);
    });
  });
}
