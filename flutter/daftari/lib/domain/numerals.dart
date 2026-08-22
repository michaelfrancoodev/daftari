/// Spoken Swahili numbers, converted to integers.
///
/// This is the single largest source of financial error in the product. A
/// misheard "laki" turns two hundred thousand into two thousand, and a
/// ledger that is quietly wrong is worse than no ledger because it will be
/// believed.
///
/// Every word here is written by hand. An expression this parser does not
/// fully recognise returns null, so the caller can ask rather than accept a
/// plausible wrong number.
///
/// NOTE ON A FIXED BUG: an earlier version of this parser assumed a
/// multiplier-then-scale word order (as in "tano elfu"). Every worked
/// example in the product's own specification actually speaks the scale
/// word FIRST — "elfu tano" (5,000), "laki mbili" (200,000), "laki tano na
/// nusu" (550,000), "elfu arobaini na sita" (46,000) — and the old
/// algorithm silently produced 1,005 / 100,002 / 150,005 / 1,046 for those
/// four cases respectively. This rewrite groups every scale word with the
/// multiplier words that follow it, which is the order Swahili actually
/// uses for round scale amounts.
abstract final class Numerals {
  /// Units and tens — combine additively within a scale group, e.g.
  /// "arobaini na sita" (40 + 6) = 46.
  static const Map<String, int> _atoms = <String, int>{
    'sifuri': 0,
    'moja': 1,
    'mbili': 2,
    'tatu': 3,
    'nne': 4,
    'tano': 5,
    'sita': 6,
    'saba': 7,
    'nane': 8,
    'tisa': 9,
    'kumi': 10,
    'ishirini': 20,
    'thelathini': 30,
    'arobaini': 40,
    'hamsini': 50,
    'sitini': 60,
    'sabini': 70,
    'themanini': 80,
    'tisini': 90,
  };

  /// Scale words. Each is spoken *before* the number that multiplies it —
  /// "mia tatu" (hundred three = 300), "elfu tano" (thousand five = 5,000),
  /// "laki mbili" (lakh two = 200,000), "milioni mbili" (2,000,000).
  static const Map<String, int> _scales = <String, int>{
    'mia': 100,
    'elfu': 1000,
    'laki': 100000,
    'milioni': 1000000,
  };

  /// Fractions, which add directly to the multiplier they follow:
  /// "tano na nusu" is five-and-a-half, which then multiplies its scale —
  /// "laki tano na nusu" is 100,000 × 5.5 = 550,000.
  static const Map<String, double> _fractions = <String, double>{
    'nusu': 0.5,
    'robo': 0.25,
  };

  /// Words carrying no numeric meaning, skipped rather than rejected.
  static const Set<String> _fillers = <String>{
    'na',
    'ya',
    'za',
    'wa',
    'kwa',
    'shilingi',
    'tsh',
    'tzs',
  };

  /// Parses a spoken or written amount.
  ///
  /// Accepts digits, words, and mixtures of the two. Returns null when the
  /// expression cannot be resolved with confidence.
  static int? parse(String input) {
    final String cleaned = input.toLowerCase().replaceAll(RegExp(r'[.,]'), '').trim();
    if (cleaned.isEmpty) return null;

    // A bare number needs no interpretation.
    final int? direct = int.tryParse(cleaned);
    if (direct != null) return direct;

    final List<String> words = cleaned
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty && !_fillers.contains(w))
        .toList(growable: false);
    if (words.isEmpty) return null;

    double total = 0;
    bool sawAnything = false;
    int i = 0;

    while (i < words.length) {
      final String word = words[i];
      final int? scale = _scales[word];

      if (scale != null) {
        // Gather every atom/fraction word that follows, up to the next
        // scale word — that whole run is this scale's multiplier.
        double group = 0;
        int j = i + 1;
        while (j < words.length && !_scales.containsKey(words[j])) {
          final String w2 = words[j];
          final int? digit = int.tryParse(w2);
          if (digit != null) {
            group = _combine(group, digit);
          } else if (_atoms.containsKey(w2)) {
            group = _combine(group, _atoms[w2]!);
          } else if (_fractions.containsKey(w2)) {
            group += _fractions[w2]!;
          } else {
            return null; // An unrecognised word inside a scale group.
          }
          j++;
        }
        // A bare scale word with nothing after it means exactly one of it.
        if (group == 0) group = 1;
        total += scale * group;
        i = j;
        sawAnything = true;
        continue;
      }

      final int? digit = int.tryParse(word);
      if (digit != null) {
        total += digit;
        i++;
        sawAnything = true;
        continue;
      }

      final int? atom = _atoms[word];
      if (atom != null) {
        // A number with no scale word at all — "tano" alone, or
        // "arobaini na sita" (46) with nothing multiplying it.
        double group = _combine(0, atom);
        int j = i + 1;
        while (j < words.length &&
            !_scales.containsKey(words[j]) &&
            (_atoms.containsKey(words[j]) || _fractions.containsKey(words[j]) || int.tryParse(words[j]) != null)) {
          final String w2 = words[j];
          final int? d2 = int.tryParse(w2);
          if (d2 != null) {
            group = _combine(group, d2);
          } else if (_atoms.containsKey(w2)) {
            group = _combine(group, _atoms[w2]!);
          } else {
            group += _fractions[w2]!;
          }
          j++;
        }
        total += group;
        i = j;
        sawAnything = true;
        continue;
      }

      final double? fraction = _fractions[word];
      if (fraction != null) {
        total += fraction;
        i++;
        sawAnything = true;
        continue;
      }

      // An unrecognised word means this is not purely a number. Refuse
      // rather than return a partial reading of what the user said.
      return null;
    }

    if (!sawAnything || total <= 0 || !total.isFinite) return null;
    return total.round();
  }

  /// Combines one more atom into the multiplier being built for the
  /// current scale group. Tens-then-ones combine additively — "arobaini"
  /// (40) then "sita" (6) is 46, not 240 or 4×6.
  static double _combine(double current, int atomValue) {
    if (current == 0) return atomValue.toDouble();
    if (current < 100 && atomValue < 10) return current + atomValue;
    return current + atomValue;
  }

  /// Parses a decimal quantity such as "nne nukta mbili" or "4.2".
  ///
  /// Gold is spoken to tenths, so this exists separately from [parse], which
  /// only ever returns whole units.
  static double? parseQuantity(String input) {
    final String cleaned = input.toLowerCase().trim();
    if (cleaned.isEmpty) return null;

    final double? direct = double.tryParse(cleaned.replaceAll(',', '.'));
    if (direct != null) return direct;

    // "point" and "nukta" both introduce a decimal part.
    final RegExp decimal = RegExp(r'\b(nukta|point)\b');
    if (decimal.hasMatch(cleaned)) {
      final List<String> halves =
          cleaned.split(decimal).where((String s) => s.trim().isNotEmpty && s != 'nukta' && s != 'point').toList(growable: false);

      if (halves.length >= 2) {
        final int? whole = parse(halves[0]);
        final int? part = parse(halves[1]);
        if (whole != null && part != null) {
          return double.parse('$whole.$part');
        }
      }
      return null;
    }

    final int? whole = parse(cleaned);
    return whole?.toDouble();
  }
}
