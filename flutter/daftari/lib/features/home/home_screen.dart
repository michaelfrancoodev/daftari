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

/// Screen 4 — Nyumbani (Home). The screen that matters, and on most days
/// the only one.
///
/// DAFTARI never fetches, caches, or displays a "gold price" anywhere —
/// gold varies by purity, grade, and buyer, and a single published figure
/// would misrepresent what any individual miner actually receives. The
/// largest figure on this screen is therefore always the user's own cost
/// per gram, computed entirely from their own entries.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appName, style: const TextStyle(letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go("/settings"),
          ),
        ],
      ),
      bottomNavigationBar: DaftariBottomNav(currentIndex: 0, role: settings.role),
      body: StreamBuilder<List<Entry>>(
        stream: repo.watchToday(),
        builder: (context, snap) {
          final entries = snap.data ?? const <Entry>[];
          final batch = Ledger.summariseBatch(entries);

          return ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              Text("${l.homeGreeting} 👋", style: const TextStyle(fontSize: 16, color: AppColor.inkMuted)),
              const SizedBox(height: Gap.lg),

              _CostHero(batch: batch, locale: locale, l: l),

              const SizedBox(height: Gap.xl),

              // The single gold element on this screen — the one action the
              // user is meant to take (screen rule #6).
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

              const SizedBox(height: Gap.xl),

              SectionLabel(l.homeCaptureType),
              const SizedBox(height: Gap.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Gap.sm,
                crossAxisSpacing: Gap.sm,
                childAspectRatio: 2.6,
                children: [
                  for (final chip in chipsForRole(settings.role, l))
                    OutlinedButton(
                      onPressed: () => context.push("/capture/quick", extra: chip.kind),
                      child: Text(chip.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),

              const SizedBox(height: Gap.md),
              OutlinedButton.icon(
                onPressed: () => context.push("/capture/type"),
                icon: const Icon(Icons.keyboard_outlined, size: 18),
                label: Text(l.homeCaptureType),
              ),

              const SizedBox(height: Gap.xl),

              if (entries.isEmpty)
                Text(l.homeNoEntriesToday, style: const TextStyle(color: AppColor.inkMuted))
              else
                InkWell(
                  onTap: () => context.push("/batch"),
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
                        Text(l.homeBatchSummary, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          batch.hasYield && batch.costPerGram != null
                              ? "${formatMoney(batch.costPerGram!, locale)} / g"
                              : formatMoney(batch.costs, locale),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                        const Icon(Icons.chevron_right, color: AppColor.inkMuted),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CostHero extends StatelessWidget {
  const _CostHero({required this.batch, required this.locale, required this.l});

  final BatchSummary batch;
  final String locale;
  final L l;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: AppColor.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColor.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l.homeYourCostLabel),
          const SizedBox(height: Gap.xs),
          if (batch.hasYield && batch.costPerGram != null)
            Text(
              "${formatMoney(batch.costPerGram!, locale)} / g",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColor.ink, fontFeatures: [FontFeature.tabularFigures()]),
            )
          else
            Text(l.homeNoYieldYet, style: const TextStyle(fontSize: 16, color: AppColor.inkMuted)),
          const SizedBox(height: Gap.sm),
          Text(l.homeCostNote, style: const TextStyle(fontSize: 12, color: AppColor.inkMuted)),
        ],
      ),
    );
  }
}
