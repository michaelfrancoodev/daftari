import '../core/money.dart';
import 'entry.dart';
import 'enums.dart';

/// What a batch cost, and what it produced.
final class BatchSummary {
  const BatchSummary({required this.costs, required this.grams});

  final Money costs;
  final double grams;

  bool get hasYield => grams > 0;

  Money? get costPerGram => costs.dividedBy(grams);
}

/// Money in, money out, and how much of the day is actually known.
final class DaySummary {
  const DaySummary({
    required this.moneyIn,
    required this.moneyOut,
    required this.entryCount,
    required this.incompleteCount,
  });

  final Money moneyIn;
  final Money moneyOut;
  final int entryCount;
  final int incompleteCount;

  /// A report that hides its own gaps is a report that lies, so this is
  /// always shown, never buried in a menu.
  int get completeness {
    if (entryCount == 0) return 100;
    return (((entryCount - incompleteCount) * 100) / entryCount).round();
  }
}

/// What a buyer's offer is actually worth to this user, in this user's own
/// terms only.
///
/// DAFTARI deliberately never publishes, fetches, or compares against any
/// "gold price" — gold varies by purity, grade, and buyer, so a single
/// published figure would misrepresent what any individual miner actually
/// receives. Rule #11 exists specifically to rule this out: the only two
/// numbers this type ever compares are what a batch cost the user to
/// produce and what a buyer is offering for it right now. Both come
/// directly from the user's own entries — nothing here is fetched,
/// estimated, or looked up.
final class MarginAssessment {
  const MarginAssessment({
    required this.offeredTotal,
    required this.costTotal,
    required this.profit,
    required this.profitPerGram,
  });

  final Money offeredTotal;
  final Money costTotal;
  final Money profit;
  final Money profitPerGram;

  bool get isProfitable => profit.isPositive || profit.isZero;
}

/// Pure arithmetic over the ledger. No database, no Flutter, no network —
/// which is what makes every rule here testable in isolation and instant on
/// the device.
abstract final class Ledger {
  static const List<EntryKind> _moneyIn = <EntryKind>[EntryKind.sale, EntryKind.repayment];

  static const List<EntryKind> _costKinds = <EntryKind>[
    EntryKind.orePurchase,
    EntryKind.fuel,
    EntryKind.milling,
    EntryKind.wages,
    EntryKind.loan,
  ];

  static BatchSummary summariseBatch(List<Entry> entries) {
    final List<Entry> live = entries.where((Entry e) => e.isLive).toList(growable: false);

    final Money costs = sumMoney(
      live.where((Entry e) => _costKinds.contains(e.kind)).map((Entry e) => e.amount ?? Money.zero),
    );

    final double grams = live
        .where((Entry e) => e.kind == EntryKind.goldYield)
        .map((Entry e) => e.quantity ?? 0)
        .fold(0.0, (double a, double b) => a + b);

    return BatchSummary(costs: costs, grams: grams);
  }

  static DaySummary summariseDay(List<Entry> entries) {
    final List<Entry> live = entries.where((Entry e) => e.isLive).toList(growable: false);

    final Money moneyIn = sumMoney(
      live.where((Entry e) => _moneyIn.contains(e.kind)).map((Entry e) => e.amount ?? Money.zero),
    );
    final Money moneyOut = sumMoney(
      live.where((Entry e) => !_moneyIn.contains(e.kind)).map((Entry e) => e.amount ?? Money.zero),
    );

    return DaySummary(
      moneyIn: moneyIn,
      moneyOut: moneyOut,
      entryCount: live.length,
      incompleteCount: live.where((Entry e) => !e.isSettled).length,
    );
  }

  /// Groups live entries by the capture that produced them, preserving
  /// insertion order within each group. The user recalls moments, not
  /// categories.
  static Map<String, List<Entry>> groupByCapture(List<Entry> entries) {
    final Map<String, List<Entry>> grouped = <String, List<Entry>>{};
    for (final Entry entry in entries.where((Entry e) => e.isLive)) {
      grouped.putIfAbsent(entry.captureId, () => <Entry>[]).add(entry);
    }
    return grouped;
  }

  /// Groups live entries by calendar day (most recent day first), each
  /// day's key truncated to midnight — the basis of Home's "recent
  /// reports" list. A day with zero entries never appears here; the
  /// caller decides whether an empty day is worth showing at all.
  static Map<DateTime, List<Entry>> groupByDay(List<Entry> entries) {
    final Map<DateTime, List<Entry>> grouped = <DateTime, List<Entry>>{};
    for (final Entry entry in entries.where((Entry e) => e.isLive)) {
      final DateTime day = DateTime(entry.occurredAt.year, entry.occurredAt.month, entry.occurredAt.day);
      grouped.putIfAbsent(day, () => <Entry>[]).add(entry);
    }
    final List<DateTime> sortedKeys = grouped.keys.toList()..sort((DateTime a, DateTime b) => b.compareTo(a));
    return <DateTime, List<Entry>>{for (final DateTime day in sortedKeys) day: grouped[day]!};
  }

  static Money valueOf({required Money perGram, required double grams}) => Money((perGram.units * grams).round());

  /// Compares a buyer's offer against what a batch actually cost the user
  /// to produce. This is the entire "before you sell" comparison DAFTARI
  /// makes — deliberately just these two numbers, both under the user's
  /// own control, and nothing fetched from anywhere.
  static MarginAssessment assessMargin({
    required Money offerPerGram,
    required Money costPerGram,
    required double grams,
  }) {
    final Money offeredTotal = valueOf(perGram: offerPerGram, grams: grams);
    final Money costTotal = valueOf(perGram: costPerGram, grams: grams);
    final Money profit = offeredTotal - costTotal;
    final Money profitPerGram = offerPerGram - costPerGram;

    return MarginAssessment(
      offeredTotal: offeredTotal,
      costTotal: costTotal,
      profit: profit,
      profitPerGram: profitPerGram,
    );
  }
}
