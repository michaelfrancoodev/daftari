import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../app/router.dart";
import "../../core/money.dart";
import "../../data/ledger_repository.dart";
import "../../domain/enums.dart";
import "../../domain/interpreter.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 8 — Uthibitisho / Kagua Kumbukumbu (Review).
///
/// One card per transaction found, each with a check or a question mark.
/// Uncertain items never block certain ones — "save all" keeps the good
/// records and leaves the rest flagged for the Inbox (Screen 12).
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.args});

  final ReviewArgs args;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<DraftEntry> _drafts = List.of(widget.args.drafts);
  bool _saving = false;

  Future<void> _editDraft(int index) async {
    final l = L.of(context);
    final draft = _drafts[index];
    final amountController = TextEditingController(text: draft.amount?.units.toString() ?? "");
    final quantityController = TextEditingController(text: draft.quantity?.toString() ?? "");
    final counterpartyController = TextEditingController(text: draft.counterparty ?? "");

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: Gap.lg,
          right: Gap.lg,
          top: Gap.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + Gap.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(draft.sourceSpan, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColor.inkMuted)),
            const SizedBox(height: Gap.md),
            if (draft.uncertainFields.contains(EntryField.amount))
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.reviewAmountLabel),
              ),
            if (draft.uncertainFields.contains(EntryField.quantity))
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.reviewWeightLabel),
              ),
            if (draft.uncertainFields.contains(EntryField.counterparty))
              TextField(
                controller: counterpartyController,
                decoration: InputDecoration(labelText: l.captureQuickWho),
              ),
            const SizedBox(height: Gap.md),
            ElevatedButton(onPressed: () => context.pop(true), child: Text(l.actionCorrect)),
          ],
        ),
      ),
    );

    if (result != true) return;

    final Set<EntryField> remaining = Set.of(draft.uncertainFields);
    final Money? amount = Money.tryParse(amountController.text);
    final double? quantity = double.tryParse(quantityController.text);
    final String? counterparty = counterpartyController.text.trim().isEmpty ? null : counterpartyController.text.trim();

    if (amount != null) remaining.remove(EntryField.amount);
    if (quantity != null) remaining.remove(EntryField.quantity);
    if (counterparty != null) remaining.remove(EntryField.counterparty);

    setState(() {
      _drafts[index] = DraftEntry(
        kind: draft.kind,
        sourceSpan: draft.sourceSpan,
        uncertainFields: remaining,
        amount: amount ?? draft.amount,
        quantity: quantity ?? draft.quantity,
        counterparty: counterparty ?? draft.counterparty,
        note: draft.note,
      );
    });
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final repo = context.read<LedgerRepository>();
    final result = await repo.commit(
      verbatimText: widget.args.verbatimText,
      source: widget.args.source,
      languageCode: widget.args.languageCode,
      drafts: _drafts,
      audioPath: widget.args.audioPath,
    );
    if (!mounted) return;
    context.pushReplacement("/capture/confirmation", extra: ConfirmationArgs(capture: result.capture, entries: result.entries));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)),
      body: _drafts.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.reviewNoTransactionsFound, textAlign: TextAlign.center),
                  const SizedBox(height: Gap.lg),
                  OutlinedButton(onPressed: () => context.pop(), child: Text(l.actionRetry)),
                  const SizedBox(height: Gap.sm),
                  TextButton(
                    onPressed: () => context.pushReplacement("/capture/type"),
                    child: Text(l.captureSwitchToType),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Gap.lg),
              children: [
                Text(l.reviewTranscriptLabel, style: const TextStyle(fontSize: 12, color: AppColor.inkMuted)),
                Text(widget.args.verbatimText, style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: Gap.lg),
                for (int i = 0; i < _drafts.length; i++) _DraftCard(draft: _drafts[i], locale: locale, l: l, onTap: () => _editDraft(i)),
              ],
            ),
      bottomNavigationBar: _drafts.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Gap.lg),
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAll,
                  child: _saving ? const CircularProgressIndicator() : Text(l.actionSaveAll),
                ),
              ),
            ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft, required this.locale, required this.l, required this.onTap});

  final DraftEntry draft;
  final String locale;
  final L l;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settled = draft.isSettled;
    return Card(
      margin: const EdgeInsets.only(bottom: Gap.sm),
      child: ListTile(
        onTap: settled ? null : onTap,
        leading: Icon(settled ? Icons.check_circle : Icons.help_outline, color: settled ? AppColor.fresh : AppColor.gold),
        title: Text(draft.sourceSpan, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          draft.amount != null
              ? formatMoney(draft.amount!, locale)
              : draft.quantity != null
                  ? "${draft.quantity} ${l.unitGrams}"
                  : settled
                      ? l.reviewStatusSettled
                      : l.reviewLowConfidence,
        ),
        trailing: settled ? null : TextButton(onPressed: onTap, child: Text(l.actionCorrect)),
      ),
    );
  }
}
