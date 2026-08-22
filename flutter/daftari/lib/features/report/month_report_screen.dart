import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../core/money.dart";
import "../../data/ledger_repository.dart";
import "../../domain/entry.dart";
import "../../domain/enums.dart";
import "../../domain/ledger.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 15 — Ripoti ya Mwezi (Month report).
///
/// The month in one screen. Never recomputed from scratch — a projection
/// over the same live entries the day report reads, so a month total can
/// never disagree with the days beneath it. Completeness sits where it
/// cannot be missed: a report that hides its own gaps is a report that
/// lies.
class MonthReportScreen extends StatefulWidget {
  const MonthReportScreen({super.key});

  @override
  State<MonthReportScreen> createState() => _MonthReportScreenState();
}

class _MonthReportScreenState extends State<MonthReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
            Text("${_month.month}/${_month.year}"),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {})],
      ),
      bottomNavigationBar: DaftariBottomNav(currentIndex: 3, role: settings.role),
      body: FutureBuilder<List<Entry>>(
        future: repo.entriesForMonth(_month),
        builder: (context, snap) {
          final entries = snap.data ?? const <Entry>[];
          final day = Ledger.summariseDay(entries); // Same money-in/out arithmetic, over a wider range.
          final batch = Ledger.summariseBatch(entries);

          final suppliers = <String, double>{};
          for (final e in entries.where((e) => e.isLive && e.kind == EntryKind.orePurchase && e.counterparty != null)) {
            suppliers[e.counterparty!] = (suppliers[e.counterparty!] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              FigureRow(label: l.monthReportMoneyIn, value: formatMoney(day.moneyIn, locale)),
              FigureRow(label: l.monthReportMoneyOut, value: formatMoney(day.moneyOut, locale)),
              FigureRow(label: l.monthReportNet, value: formatMoney(day.moneyIn - day.moneyOut, locale), emphasize: true),
              const Divider(height: Gap.xl),
              SectionLabel(l.monthReportProduction),
              FigureRow(label: l.batchYield, value: "${batch.grams} ${l.unitGrams}"),
              FigureRow(label: l.batchCostPerGram, value: batch.costPerGram != null ? formatMoney(batch.costPerGram!, locale) : "—"),
              const Divider(height: Gap.xl),
              if (suppliers.isNotEmpty) ...[
                SectionLabel(l.monthReportSuppliers),
                for (final s in suppliers.entries) FigureRow(label: s.key, value: "${s.value.toInt()}"),
                const Divider(height: Gap.xl),
              ],
              SectionLabel(l.monthReportCompleteness),
              FigureRow(label: l.dayReportCompleteness, value: "${day.completeness}%", emphasize: true),
            ],
          );
        },
      ),
    );
  }
}
