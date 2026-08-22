import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../data/ledger_repository.dart";
import "../../domain/entry.dart";
import "../../domain/ledger.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 13 — Siku ya Leo (Today).
///
/// A day is the unit a miner actually thinks in. The timeline groups by
/// utterance (capture), newest first — one link back per group, not one
/// per line — because the user remembers moments, not categories. The
/// "Maelezo Yako" block underneath holds their own words, unedited.
class DayReportScreen extends StatelessWidget {
  const DayReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l.dayReportTitle)),
      body: StreamBuilder<List<Entry>>(
        stream: repo.watchToday(),
        builder: (context, snap) {
          final entries = snap.data ?? const <Entry>[];
          final day = Ledger.summariseDay(entries);
          final grouped = Ledger.groupByCapture(entries);

          return ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              FigureRow(label: l.dayReportMoneyIn, value: formatMoney(day.moneyIn, locale)),
              FigureRow(label: l.dayReportMoneyOut, value: formatMoney(day.moneyOut, locale)),
              const Divider(height: Gap.xl),
              FigureRow(label: l.dayReportCompleteness, value: "${day.completeness}%", emphasize: true),
              if (day.incompleteCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.xs),
                  child: StatusDot(color: AppColor.ageing, label: l.dayReportGapWarning),
                ),
              const SizedBox(height: Gap.xl),
              SectionLabel(l.dayReportYourWords),
              const SizedBox(height: Gap.sm),
              for (final captureId in grouped.keys)
                _CaptureGroup(
                  captureId: captureId,
                  entries: grouped[captureId]!,
                  locale: locale,
                  l: l,
                  onViewOrigin: () => context.push("/origin/$captureId"),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CaptureGroup extends StatelessWidget {
  const _CaptureGroup({required this.captureId, required this.entries, required this.locale, required this.l, required this.onViewOrigin});

  final String captureId;
  final List<Entry> entries;
  final String locale;
  final L l;
  final VoidCallback onViewOrigin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Gap.sm),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(color: AppColor.surfaceRaised, borderRadius: BorderRadius.circular(Radii.md), border: Border.all(color: AppColor.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(e.note ?? e.kind.name, overflow: TextOverflow.ellipsis)),
                  Text(
                    e.amount != null ? formatMoney(e.amount!, locale) : e.quantity != null ? "${e.quantity} ${l.unitGrams}" : "—",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Gap.xs),
          TextButton(onPressed: onViewOrigin, child: Text(l.dayReportViewOrigin)),
        ],
      ),
    );
  }
}
