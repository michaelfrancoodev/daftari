import "package:flutter_test/flutter_test.dart";
import "package:daftari/domain/numerals.dart";

void main() {
  group("Numerals.parse — scale-word-first amounts", () {
    // These five cases are the worked examples from the product's own
    // Master Specification (Definition of Done, section B) and Project
    // Report. An earlier version of this parser assumed the opposite word
    // order and produced 1005, 100002, 150005 and 1046 for four of these
    // five inputs — this test suite exists specifically to keep that
    // regression from coming back.
    test("elfu tano is five thousand", () {
      expect(Numerals.parse("elfu tano"), 5000);
    });

    test("laki mbili is two hundred thousand", () {
      expect(Numerals.parse("laki mbili"), 200000);
    });

    test("elfu arobaini na sita is forty-six thousand", () {
      expect(Numerals.parse("elfu arobaini na sita"), 46000);
    });

    test("elfu ishirini na tano is twenty-five thousand", () {
      expect(Numerals.parse("elfu ishirini na tano"), 25000);
    });

    test("laki tano na nusu is five hundred fifty thousand", () {
      expect(Numerals.parse("laki tano na nusu"), 550000);
    });
  });

  group("Numerals.parse — additional coverage", () {
    test("milioni mbili is two million", () {
      expect(Numerals.parse("milioni mbili"), 2000000);
    });

    test("mia tatu is three hundred", () {
      expect(Numerals.parse("mia tatu"), 300);
    });

    test("laki tisa na robo is nine hundred twenty-five thousand", () {
      expect(Numerals.parse("laki tisa na robo"), 925000);
    });

    test("a bare atom with no scale word", () {
      expect(Numerals.parse("tano"), 5);
    });

    test("a compound atom with no scale word", () {
      expect(Numerals.parse("arobaini na sita"), 46);
    });

    test("a bare digit string", () {
      expect(Numerals.parse("500000"), 500000);
    });

    test("digit strings with thousands separators are cleaned before parsing", () {
      expect(Numerals.parse("500,000"), 500000);
    });

    test("a bare scale word with nothing after it means exactly one", () {
      expect(Numerals.parse("elfu"), 1000);
    });

    test("filler words are ignored throughout", () {
      expect(Numerals.parse("shilingi elfu tano"), 5000);
    });

    test("an unrecognised word refuses rather than guesses", () {
      expect(Numerals.parse("laki therusi"), isNull);
    });

    test("empty input returns null", () {
      expect(Numerals.parse(""), isNull);
    });

    test("whitespace-only input returns null", () {
      expect(Numerals.parse("   "), isNull);
    });

    test("zero resolves to null, not a valid amount", () {
      expect(Numerals.parse("sifuri"), isNull);
    });
  });

  group("Numerals.parseQuantity", () {
    test("a plain decimal", () {
      expect(Numerals.parseQuantity("4.2"), 4.2);
    });

    test("a decimal with a comma", () {
      expect(Numerals.parseQuantity("4,2"), 4.2);
    });

    test("spoken with nukta", () {
      expect(Numerals.parseQuantity("nne nukta mbili"), 4.2);
    });

    test("spoken with point", () {
      expect(Numerals.parseQuantity("nne point mbili"), 4.2);
    });

    test("an ambiguous spoken decimal refuses rather than guesses", () {
      // From the Master Specification, test B4: "point moja therusi saba"
      // must resolve to a question mark, never a plausible wrong reading.
      expect(Numerals.parseQuantity("point moja therusi saba"), isNull);
    });

    test("a whole number with no decimal part", () {
      expect(Numerals.parseQuantity("tano"), 5.0);
    });

    test("empty input returns null", () {
      expect(Numerals.parseQuantity(""), isNull);
    });
  });
}
