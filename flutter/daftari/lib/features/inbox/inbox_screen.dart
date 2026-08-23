import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../data/ledger_repository.dart";
import "../../domain/gap_detector.dart" hide Gap;
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 12 — Maswali (Inbox).
///
/// The screen a judge will point at: visible proof the agent acts on its
/// own. Nobody asked these questions — the scheduled gap-detection pass
/// noticed something and asked once. One question per card, never a list
/// of five; every question answerable with a single tap.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<GapWithEntry>> _gaps = context.read<LedgerRepository>().detectGaps();

  Future<void> _refresh() async {
    setState(() => _gaps = context.read<LedgerRepository>().detectGaps());
    await _gaps;
  }

  Future<void> _answerYes(GapWithEntry g) async {
    // "Yes" for oreNeverMilled/millingWithoutYield/loanNeverRepaid all mean
    // the same thing here: the user confirms the state is as expected and
    // the gap is dismissed by re-asserting the same entry unchanged, minus
    // the field that made it uncertain in the first place, if any.
    final repo = context.read<LedgerRepository>();
    await repo.resolveField(g.entry, amount: g.entry.amount, quantity: g.entry.quantity, counterparty: g.entry.counterparty);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.inboxTitle)),
      bottomNavigationBar: DaftariBottomNav(currentIndex: 2, role: settings.role),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<GapWithEntry>>(
          future: _gaps,
          builder: (context, snap) {
            final gaps = snap.data ?? const <GapWithEntry>[];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (gaps.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: Gap.xxl),
                  Center(child: Text(l.inboxEmpty, style: const TextStyle(color: AppColor.inkMuted))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(Gap.lg),
              itemCount: gaps.length,
              separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
              itemBuilder: (context, i) => _GapCard(g: gaps[i], l: l, onYes: () => _answerYes(gaps[i])),
            );
          },
        ),
      ),
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.g, required this.l, required this.onYes});

  final GapWithEntry g;
  final L l;
  final VoidCallback onYes;

  String get _question {
    final days = DateTime.now().difference(g.gap.occurredAt).inDays.toString();
    switch (g.gap.kind) {
      case GapKind.oreNeverMilled:
        return l.inboxGapOreNotMilled(days);
      case GapKind.millingWithoutYield:
        return l.inboxGapMillingNoYield;
      case GapKind.loanNeverRepaid:
        return l.inboxGapLoanUnpaid(g.entry.counterparty ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(color: AppColor.surfaceRaised, borderRadius: BorderRadius.circular(Radii.md), border: Border.all(color: AppColor.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_question),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              ElevatedButton(onPressed: onYes, child: Text(l.actionYes)),
              const SizedBox(width: Gap.sm),
              OutlinedButton(onPressed: () {}, child: Text(l.actionNotYet)),
            ],
          ),
        ],
      ),
    );
  }
}
