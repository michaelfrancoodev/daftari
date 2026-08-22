import 'entry.dart';
import 'enums.dart';

/// The kinds of gap worth raising.
enum GapKind { oreNeverMilled, millingWithoutYield, loanNeverRepaid }

/// Something the ledger noticed and cannot resolve alone.
final class Gap {
  const Gap({
    required this.kind,
    required this.entryId,
    required this.occurredAt,
  });

  final GapKind kind;
  final String entryId;
  final DateTime occurredAt;
}

/// Notices what has not been recorded.
///
/// Pure functions with no database and no Flutter, so every rule here is
/// testable in isolation and runs instantly on the device.
abstract final class GapDetector {
  /// How long ore may sit unmilled before it is worth asking about.
  static const Duration _orePatience = Duration(days: 3);

  /// How long a loan may sit untouched before it is worth asking about.
  static const Duration _loanPatience = Duration(days: 60);

  static List<Gap> detect(List<Entry> entries, DateTime now) {
    final List<Entry> live = entries.where((Entry e) => e.isLive).toList(growable: false);

    return <Gap>[
      ..._oreNeverMilled(live, now),
      ..._millingWithoutYield(live, now),
      ..._loansNeverRepaid(live, now),
    ];
  }

  /// Ore was bought, and days later nothing has been milled.
  static Iterable<Gap> _oreNeverMilled(List<Entry> entries, DateTime now) {
    final bool milled = entries.any((Entry e) => e.kind == EntryKind.milling);
    if (milled) return const <Gap>[];

    return entries
        .where((Entry e) => e.kind == EntryKind.orePurchase && now.difference(e.occurredAt) > _orePatience)
        .map(
          (Entry e) => Gap(
            kind: GapKind.oreNeverMilled,
            entryId: e.id,
            occurredAt: e.occurredAt,
          ),
        );
  }

  /// A mill ran and no yield was ever recorded against it.
  static Iterable<Gap> _millingWithoutYield(List<Entry> entries, DateTime now) {
    final bool hasYield = entries.any((Entry e) => e.kind == EntryKind.goldYield);
    if (hasYield) return const <Gap>[];

    return entries
        .where((Entry e) => e.kind == EntryKind.milling && now.difference(e.occurredAt) > const Duration(days: 1))
        .map(
          (Entry e) => Gap(
            kind: GapKind.millingWithoutYield,
            entryId: e.id,
            occurredAt: e.occurredAt,
          ),
        );
  }

  /// Money was lent and neither repaid nor mentioned since.
  static Iterable<Gap> _loansNeverRepaid(List<Entry> entries, DateTime now) {
    final Set<String> repaid =
        entries.where((Entry e) => e.kind == EntryKind.repayment).map((Entry e) => e.counterparty).whereType<String>().toSet();

    return entries
        .where(
          (Entry e) =>
              e.kind == EntryKind.loan &&
              e.counterparty != null &&
              !repaid.contains(e.counterparty) &&
              now.difference(e.occurredAt) > _loanPatience,
        )
        .map(
          (Entry e) => Gap(
            kind: GapKind.loanNeverRepaid,
            entryId: e.id,
            occurredAt: e.occurredAt,
          ),
        );
  }
}
