import "../../core/money.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../data/ledger_repository.dart";
import "../../domain/entry.dart";
import "../../domain/enums.dart";
import "../../domain/ledger.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 10 — Batch Hii (This batch).
///
/// The screen where the ledger finally answers the question paper never
/// could: cost per gram. Every total expands into the entries behind it —
/// screen rule #7 — which is what makes the month report believable later.
class BatchScreen extends StatelessWidget {
  const BatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l.batchTitle)),
      body: StreamBuilder<List<Entry>>(
        stream: repo.watchToday(),
        builder: (context, snap) {
          final entries = snap.data ?? const <Entry>[];
          final batch = Ledger.summariseBatch(entries);
          final costEntries = entries.where((e) => e.isLive && e.kind != EntryKind.goldYield && e.kind != EntryKind.sale).toList();

          final byKind = <EntryKind, List<Entry>>{};
          for (final e in costEntries) {
            byKind.putIfAbsent(e.kind, () => []).add(e);
          }

          return ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              SectionLabel(l.batchCostBreakdown),
              for (final kind in byKind.keys)
                FigureRow(
                  label: _kindLabel(kind, l),
                  value: formatMoney(
                    sumMoney(byKind[kind]!.map((e) => e.amount ?? Money.zero)),
                    locale,
                  ),
                ),
              const Divider(height: Gap.xl),
              FigureRow(label: l.batchTotalCost, value: formatMoney(batch.costs, locale), emphasize: true),
              FigureRow(label: l.batchYield, value: "${batch.grams} ${l.unitGrams}"),
              const SizedBox(height: Gap.md),
              Container(
                padding: const EdgeInsets.all(Gap.lg),
                decoration: BoxDecoration(color: AppColor.ink, borderRadius: BorderRadius.circular(Radii.lg)),
                child: Column(
                  children: [
                    SectionLabel(l.batchCostPerGram),
                    const SizedBox(height: Gap.xs),
                    Text(
                      batch.costPerGram != null ? "${formatMoney(batch.costPerGram!, locale)} / g" : "—",
                      style: const TextStyle(color: AppColor.surface, fontSize: 34, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              const SizedBox(height: Gap.xl),
              ElevatedButton(
                onPressed: () => context.push("/presale"),
                child: Text(l.batchBeforeSelling),
              ),
            ],
          );
        },
      ),
    );
  }

  String _kindLabel(EntryKind kind, L l) {
    switch (kind) {
      case EntryKind.orePurchase:
        return l.chipOre;
      case EntryKind.fuel:
        return l.chipFuel;
      case EntryKind.milling:
        return l.chipMilling;
      case EntryKind.wages:
        return l.chipWages;
      case EntryKind.loan:
        return l.chipLoan;
      case EntryKind.repayment:
        return l.chipRepayment;
      case EntryKind.goldYield:
        return l.chipYield;
      case EntryKind.sale:
        return l.chipSale;
    }
  }
}
