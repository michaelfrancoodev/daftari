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

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Screen 13 — Siku (Day report).
///
/// A day is the unit a miner actually thinks in. The timeline groups by
/// utterance (capture), newest first — one link back per group, not one
/// per line — because the user remembers moments, not categories. The
/// "Maelezo Yako" block underneath holds their own words, unedited.
///
/// Reached either from Home's Recent Reports list (any day) or from the
/// bottom nav / a capture confirmation (today, live-updating as new
/// entries are saved).
class DayReportScreen extends StatelessWidget {
  const DayReportScreen({super.key, this.day});

  /// The day to show. Null means "today" and uses a live stream so the
  /// screen updates the moment a new entry is saved; any other day is a
  /// one-shot fetch, since the past does not change while it's on screen.
  final DateTime? day;

  bool get _isToday => day == null || _isSameDay(day!, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(_isToday ? l.dayReportTitle : _dateLabel(day!))),
      body: _isToday
          ? StreamBuilder<List<Entry>>(
              stream: repo.watchToday(),
              builder: (context, snap) => _DayReportBody(entries: snap.data ?? const <Entry>[], locale: locale, l: l),
            )
          : FutureBuilder<List<Entry>>(
              future: repo.entriesForDay(day!),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                return _DayReportBody(entries: snap.data!, locale: locale, l: l);
              },
            ),
    );
  }

  String _dateLabel(DateTime d) => "${d.day}/${d.month}/${d.year}";
}

class _DayReportBody extends StatelessWidget {
  const _DayReportBody({required this.entries, required this.locale, required this.l});

  final List<Entry> entries;
  final String locale;
  final L l;

  @override
  Widget build(BuildContext context) {
    final day = Ledger.summariseDay(entries);
    final grouped = Ledger.groupByCapture(entries);

    if (entries.isEmpty) {
      return Center(child: Text(l.homeNoEntriesToday, style: const TextStyle(color: AppColor.inkMuted)));
    }

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
