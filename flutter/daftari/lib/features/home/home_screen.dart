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

/// Screen 4 — Nyumbani (Home).
///
/// Deliberately just two things: a way to record what happened (by
/// speaking or typing), and a short list of recent reports to look back
/// at. Nothing else competes for attention on this screen — a busy person
/// at a working site should never have to think about which button to
/// press.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appName, style: const TextStyle(letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            // push (not go): this is a side destination reached from an
            // icon, not one of the five bottom-nav tabs — pushing keeps a
            // real back-stack entry so the platform back gesture and the
            // AppBar's own back arrow both work from Settings.
            onPressed: () => context.push("/settings"),
          ),
        ],
      ),
      bottomNavigationBar: DaftariBottomNav(currentIndex: 0, role: settings.role),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          Text("${l.homeGreeting} 👋", style: const TextStyle(fontSize: 16, color: AppColor.inkMuted)),
          const SizedBox(height: Gap.xl),

          // The two things a person can do on this screen. Recording is
          // the one gold element — the single action the screen wants —
          // typing is its equal, quieter alternative.
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => context.push("/capture/voice"),
                  child: Container(
                    width: Touch.micButton,
                    height: Touch.micButton,
                    decoration: const BoxDecoration(color: AppColor.gold, shape: BoxShape.circle),
                    child: const Icon(Icons.mic, color: AppColor.ink, size: 40),
                  ),
                ),
                const SizedBox(height: Gap.sm),
                Text(l.homeMicHint, style: const TextStyle(color: AppColor.inkMuted, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: Gap.md),
          OutlinedButton.icon(
            onPressed: () => context.push("/capture/type"),
            icon: const Icon(Icons.keyboard_outlined, size: 18),
            label: Text(l.homeCaptureType),
          ),

          const SizedBox(height: Gap.xxl),
          SectionLabel(l.homeRecentReports),
          const SizedBox(height: Gap.sm),

          FutureBuilder<List<Entry>>(
            future: repo.entriesForRecentDays(days: 7),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: Gap.lg),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final grouped = Ledger.groupByDay(snap.data!);
              if (grouped.isEmpty) {
                return Text(l.homeNoRecentReports, style: const TextStyle(color: AppColor.inkMuted));
              }

              return Column(
                children: [
                  for (final day in grouped.keys)
                    _RecentReportTile(
                      day: day,
                      entries: grouped[day]!,
                      l: l,
                      onTap: () => context.push("/day-report", extra: day),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  const _RecentReportTile({required this.day, required this.entries, required this.l, required this.onTap});

  final DateTime day;
  final List<Entry> entries;
  final L l;
  final VoidCallback onTap;

  String get _label {
    final now = DateTime.now();
    if (_isSameDay(day, now)) return l.homeTodayLabel;
    if (_isSameDay(day, now.subtract(const Duration(days: 1)))) return l.homeYesterday;
    return "${day.day}/${day.month}/${day.year}";
  }

  @override
  Widget build(BuildContext context) {
    final summary = Ledger.summariseDay(entries);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: AppColor.surfaceRaised,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: AppColor.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      "${summary.entryCount} · ${summary.completeness}%",
                      style: const TextStyle(fontSize: 12, color: AppColor.inkMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColor.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
