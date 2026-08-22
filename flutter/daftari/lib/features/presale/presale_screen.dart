import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../core/money.dart";
import "../../data/ledger_repository.dart";
import "../../domain/entry.dart";
import "../../domain/ledger.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 11 — Kabla Hujauza (Before you sell).
///
/// Exactly two numbers, both entirely within the user's own control: what
/// this batch cost to produce, and what a buyer is offering right now.
/// DAFTARI deliberately does not fetch, cache, or compare against any
/// external "gold price" — gold varies by purity, grade, and buyer, so a
/// single published figure would misrepresent what this specific miner,
/// with this specific batch, actually receives. The app never says "sell"
/// or "don't sell" anywhere on this screen.
class PresaleScreen extends StatefulWidget {
  const PresaleScreen({super.key});

  @override
  State<PresaleScreen> createState() => _PresaleScreenState();
}

class _PresaleScreenState extends State<PresaleScreen> {
  final _offerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l.presaleTitle)),
      body: StreamBuilder<List<Entry>>(
        stream: repo.watchToday(),
        builder: (context, snap) {
          final entries = snap.data ?? const <Entry>[];
          final batch = Ledger.summariseBatch(entries);
          final offer = Money.tryParse(_offerController.text);

          return ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              FigureRow(label: l.presaleYourGold, value: "${batch.grams} ${l.unitGrams}"),
              FigureRow(
                label: l.presaleYourCost,
                value: batch.costPerGram != null ? "${formatMoney(batch.costPerGram!, locale)} / g" : "—",
              ),
              const SizedBox(height: Gap.md),
              TextField(
                controller: _offerController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                decoration: InputDecoration(labelText: l.presaleBuyerOffers, suffixText: "/ g", border: const OutlineInputBorder()),
              ),
              const SizedBox(height: Gap.lg),

              if (offer != null && batch.hasYield && batch.costPerGram != null) ...[
                Builder(builder: (context) {
                  final assessment = Ledger.assessMargin(offerPerGram: offer, costPerGram: batch.costPerGram!, grams: batch.grams);
                  return Container(
                    padding: const EdgeInsets.all(Gap.lg),
                    decoration: BoxDecoration(
                      color: AppColor.surfaceRaised,
                      borderRadius: BorderRadius.circular(Radii.lg),
                      border: Border.all(color: AppColor.line),
                    ),
                    child: Column(
                      children: [
                        SectionLabel(l.presaleProfit),
                        Text(
                          formatMoney(assessment.profit, locale),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: assessment.isProfitable ? AppColor.fresh : AppColor.stale,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: Gap.xs),
                        Text(
                          "${formatMoney(assessment.profitPerGram, locale)} / g",
                          style: const TextStyle(fontSize: 13, color: AppColor.inkMuted),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: Gap.xl),
              Text(l.presaleDecisionIsYours, textAlign: TextAlign.center, style: const TextStyle(color: AppColor.inkMuted, fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}
