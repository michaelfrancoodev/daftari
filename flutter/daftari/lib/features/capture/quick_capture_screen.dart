import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../app/router.dart";
import "../../core/money.dart";
import "../../data/ledger_repository.dart";
import "../../domain/entry.dart";
import "../../domain/enums.dart";
import "../../domain/interpreter.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 7 — Kuandika Haraka (Quick capture).
///
/// A chip and a large number pad. Three taps, no reading, no ambiguity to
/// resolve — so this path writes straight to the ledger rather than
/// passing through Review.
class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key, this.initialKind});

  final EntryKind? initialKind;

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  late EntryKind _kind = widget.initialKind ?? EntryKind.orePurchase;
  String _digits = "";
  final _counterpartyController = TextEditingController();
  final _gramsController = TextEditingController();
  bool _saving = false;

  bool get _isGrams => _kind == EntryKind.goldYield;

  void _tapDigit(String d) => setState(() => _digits += d);
  void _tapThousand() => setState(() => _digits = _digits.isEmpty ? "" : "${_digits}000");
  void _backspace() => setState(() => _digits = _digits.isEmpty ? "" : _digits.substring(0, _digits.length - 1));

  Future<void> _save() async {
    final repo = context.read<LedgerRepository>();
    final settings = context.read<SettingsController>();

    final Money? amount = _isGrams ? null : Money.tryParse(_digits);
    final double? grams = _isGrams ? double.tryParse(_gramsController.text) : null;
    if (_isGrams ? grams == null : amount == null) return;

    setState(() => _saving = true);

    final draft = DraftEntry(
      kind: _kind,
      sourceSpan: _isGrams ? _gramsController.text : _digits,
      uncertainFields: const <EntryField>{},
      amount: amount,
      quantity: grams,
      counterparty: _counterpartyController.text.trim().isEmpty ? null : _counterpartyController.text.trim(),
    );

    final result = await repo.commit(
      verbatimText: draft.sourceSpan,
      source: CaptureSource.quick,
      languageCode: settings.locale.languageCode,
      drafts: [draft],
    );

    if (!mounted) return;
    context.pushReplacement("/capture/confirmation", extra: ConfirmationArgs(capture: result.capture, entries: result.entries));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final chips = chipsForRole(settings.role, l);
    final label = chips.firstWhere((c) => c.kind == _kind, orElse: () => chips.first).label;
    final needsCounterparty = _kind == EntryKind.loan || _kind == EntryKind.repayment;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.captureQuickTitle),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          children: [
            Wrap(
              spacing: Gap.sm,
              children: [
                for (final c in chips)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: _kind == c.kind,
                    onSelected: (_) => setState(() => _kind = c.kind),
                  ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            Text(label, style: const TextStyle(fontSize: 14, color: AppColor.inkMuted)),
            const SizedBox(height: Gap.sm),
            if (_isGrams)
              TextField(
                controller: _gramsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                decoration: InputDecoration(border: InputBorder.none, hintText: "0.00", suffixText: l.unitGrams),
              )
            else
              Text(
                _digits.isEmpty ? "0" : _digits,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
              ),
            if (needsCounterparty) ...[
              const SizedBox(height: Gap.md),
              TextField(
                controller: _counterpartyController,
                decoration: InputDecoration(labelText: l.captureQuickWho, border: const OutlineInputBorder()),
              ),
            ],
            const Spacer(),
            if (!_isGrams) _NumberPad(onDigit: _tapDigit, onThousand: _tapThousand, onBackspace: _backspace),
            const SizedBox(height: Gap.md),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator() : Text(l.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onDigit, required this.onThousand, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onThousand;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "000", "0", "⌫"];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Gap.sm,
      crossAxisSpacing: Gap.sm,
      childAspectRatio: 1.8,
      children: [
        for (final k in keys)
          OutlinedButton(
            onPressed: () {
              if (k == "⌫") {
                onBackspace();
              } else if (k == "000") {
                onThousand();
              } else {
                onDigit(k);
              }
            },
            child: Text(k, style: const TextStyle(fontSize: 20)),
          ),
      ],
    );
  }
}
