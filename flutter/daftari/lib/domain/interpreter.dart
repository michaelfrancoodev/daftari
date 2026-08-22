import '../core/money.dart';
import 'enums.dart';
import 'numerals.dart';

/// One transaction as first understood, before it becomes an Entry.
final class DraftEntry {
  const DraftEntry({
    required this.kind,
    required this.sourceSpan,
    required this.uncertainFields,
    this.amount,
    this.quantity,
    this.counterparty,
    this.note,
  });

  final EntryKind kind;

  /// The words this was read from, so the review card and the origin screen
  /// can both show exactly what produced it.
  final String sourceSpan;

  final Set<EntryField> uncertainFields;
  final Money? amount;
  final double? quantity;
  final String? counterparty;
  final String? note;

  bool get isSettled => uncertainFields.isEmpty;
}

/// Splits one utterance into the transactions inside it.
///
/// Runs entirely on the device. A cloud agent refines the reading later when
/// a network appears, but the user never waits for one.
abstract final class Interpreter {
  /// Words that begin a new transaction within a sentence.
  static final RegExp _separator = RegExp(
    r'\s*,\s*|\s+na\s+nime|\s+na\s+nika|\s+na\s+ni\s+',
    caseSensitive: false,
  );

  /// Verb stems that identify what a clause describes.
  ///
  /// Order matters: the first match wins, so specific stems precede general
  /// ones. "nimemrudishia" must be tested before "nimekopa".
  static const Map<EntryKind, List<String>> _verbs = <EntryKind, List<String>>{
    EntryKind.repayment: <String>['nimemrudishia', 'nimerudisha', 'marejesho'],
    EntryKind.loan: <String>['nimekopesha', 'nimekopa', 'mkopo'],
    EntryKind.wages: <String>['nimewalipa', 'nimempatia', 'nimelipa', 'vibarua'],
    EntryKind.sale: <String>['nimeuza', 'nimeuzia', 'mauzo'],
    EntryKind.goldYield: <String>['nimepata', 'nimetoa', 'imetoa'],
    EntryKind.milling: <String>['nimesaga', 'umeenda mtambo', 'kusaga'],
    EntryKind.fuel: <String>['dizeli', 'mafuta', 'umeme', 'petroli'],
    EntryKind.orePurchase: <String>['nimenunua', 'nikanunua', 'mawe', 'magunia'],
  };

  /// A capitalised name following a preposition.
  static final RegExp _counterpartyAfterPreposition = RegExp(r'\b(?:kwa|kutoka|na)\s+([A-Z][a-zA-Z]+)');

  /// Verb stems whose grammatical object is a person, spoken with no
  /// preposition at all — "Nimempatia Michael..." names Michael directly,
  /// unlike "nimekopesha kwa Salimu" which needs "kwa" first. Both forms
  /// appear side by side in the product's own worked examples, so both
  /// must resolve to a counterparty.
  static const List<String> _directObjectVerbs = <String>['nimempatia', 'nimemlipa', 'nimewalipa', 'nimemrudishia'];

  /// Interprets one utterance.
  ///
  /// Returns one draft per transaction found, in the order spoken. An empty
  /// list means nothing was understood, which the caller must surface
  /// rather than silently discard.
  static List<DraftEntry> interpret(String utterance) {
    final List<String> clauses = _split(utterance);
    final List<DraftEntry> drafts = <DraftEntry>[];

    for (final String clause in clauses) {
      final DraftEntry? draft = _interpretClause(clause);
      if (draft != null) drafts.add(draft);
    }

    return drafts;
  }

  /// Pass one: segmentation only. No values are read here.
  static List<String> _split(String utterance) =>
      utterance.split(_separator).map((String s) => s.trim()).where((String s) => s.length > 2).toList(growable: false);

  /// Pass two: interpret a single clause in isolation.
  static DraftEntry? _interpretClause(String clause) {
    final String lower = clause.toLowerCase();

    final EntryKind? kind = _kindOf(lower);
    if (kind == null) return null;

    final Set<EntryField> uncertain = <EntryField>{};

    // Gold is a quantity; everything else is an amount.
    if (kind == EntryKind.goldYield) {
      final double? grams = _extractQuantity(lower);
      if (grams == null) uncertain.add(EntryField.quantity);

      return DraftEntry(
        kind: kind,
        sourceSpan: clause,
        quantity: grams,
        amount: _extractAmount(lower).$1,
        counterparty: _extractCounterparty(clause),
        uncertainFields: uncertain,
      );
    }

    final (Money? amount, bool confident) = _extractAmount(lower);
    if (amount == null || !confident) uncertain.add(EntryField.amount);

    final String? party = _extractCounterparty(clause);

    // A loan without a named party cannot be tracked, so it must be asked.
    if (party == null && (kind == EntryKind.loan || kind == EntryKind.repayment)) {
      uncertain.add(EntryField.counterparty);
    }

    return DraftEntry(
      kind: kind,
      sourceSpan: clause,
      amount: amount,
      counterparty: party,
      note: _extractNote(clause),
      uncertainFields: uncertain,
    );
  }

  static EntryKind? _kindOf(String clause) {
    for (final MapEntry<EntryKind, List<String>> pair in _verbs.entries) {
      for (final String stem in pair.value) {
        if (clause.contains(stem)) return pair.key;
      }
    }
    return null;
  }

  /// Reads the first amount in a clause.
  ///
  /// Returns the value and whether it was read with confidence. An
  /// unresolved numeral yields no value at all rather than a plausible
  /// wrong one.
  ///
  /// The capture group below is deliberately generous — up to four words
  /// after a scale word — because a spoken amount is often followed
  /// immediately by an explanatory phrase ("elfu tano ya kufrisha ponchi").
  /// [Numerals.parse] is strict and refuses anything it does not fully
  /// recognise, so this backs off one trailing word at a time until the
  /// numeral portion parses on its own; a bare "kufrisha ponchi" tail must
  /// never cause a perfectly good "elfu tano" to be discarded.
  static (Money?, bool) _extractAmount(String clause) {
    final RegExp numeric = RegExp(
      r'\b(?:tsh|tzs|shilingi)?\s*'
      r'((?:laki|elfu|milioni|mia)(?:\s+\w+){0,4}'
      r'|\d[\d,]*)',
    );

    final RegExpMatch? match = numeric.firstMatch(clause);
    if (match == null) return (null, false);

    final String? raw = match.group(1);
    if (raw == null) return (null, false);

    final List<String> words = raw.trim().split(RegExp(r'\s+'));
    for (int end = words.length; end > 0; end--) {
      final int? value = Numerals.parse(words.sublist(0, end).join(' '));
      if (value != null) return (Money(value), true);
    }
    return (null, false);
  }

  static double? _extractQuantity(String clause) {
    final RegExp quantity = RegExp(
      r'\b(?:gramu|gram)\s+([\w\s]+?)(?:\s+kwa\b|$)'
      r'|([\d.]+)\s*(?:g|gramu)\b',
    );

    final RegExpMatch? match = quantity.firstMatch(clause);
    if (match == null) return null;

    final String? raw = match.group(1) ?? match.group(2);
    return raw == null ? null : Numerals.parseQuantity(raw.trim());
  }

  /// Reads a capitalised name.
  ///
  /// Tries a preposition first ("kwa Salimu"), then falls back to the
  /// direct-object verbs above ("Nimempatia Michael"). Capitalisation is
  /// the only reliable signal available offline — a lower-case word after
  /// "kwa" is far more often a thing than a person.
  static String? _extractCounterparty(String clause) {
    final RegExpMatch? viaPreposition = _counterpartyAfterPreposition.firstMatch(clause);
    if (viaPreposition != null) return viaPreposition.group(1);

    final String lower = clause.toLowerCase();
    for (final String verb in _directObjectVerbs) {
      final int index = lower.indexOf(verb);
      if (index == -1) continue;
      final String after = clause.substring(index + verb.length).trimLeft();
      final RegExpMatch? name = RegExp(r'^([A-Z][a-zA-Z]+)').firstMatch(after);
      if (name != null) return name.group(1);
    }
    return null;
  }

  /// Keeps the user's own explanation, such as "ya kufrisha ponchi".
  static String? _extractNote(String clause) {
    final RegExpMatch? match = RegExp(r'\bya\s+(\w+(?:\s+\w+)?)').firstMatch(clause.toLowerCase());
    return match?.group(1);
  }
}
