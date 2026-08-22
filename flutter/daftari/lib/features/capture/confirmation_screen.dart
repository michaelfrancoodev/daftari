import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../app/router.dart";
import "../../core/money.dart";
import "../../data/ledger_repository.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 9 — Uthibitisho (Confirmation).
///
/// Three seconds, and the most important three seconds in the product: it
/// confirms what was heard and returns something the user did not know a
/// second ago. Undo stays live for the full window — a mis-tap must never
/// become a permanent wrong number.
class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key, required this.result});

  final ConfirmationArgs result;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  late int _secondsLeft = Motion.undoWindow.inSeconds;
  Timer? _timer;
  bool _undone = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted && !_undone) context.go("/home");
      }
    });
  }

  Future<void> _undo() async {
    _timer?.cancel();
    setState(() => _undone = true);
    final repo = context.read<LedgerRepository>();
    for (final entry in widget.result.entries) {
      await repo.voidEntry(entry.id);
    }
    if (mounted) context.go("/home");
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final locale = settings.locale.languageCode;
    final total = widget.result.entries.fold<Money>(Money.zero, (acc, e) => acc + (e.amount ?? Money.zero));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColor.fresh, size: 56),
              const SizedBox(height: Gap.md),
              Text(l.confirmationSaved, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: Gap.sm),
              Text(
                "${widget.result.entries.length} · ${formatMoney(total, locale)}",
                style: const TextStyle(fontSize: 16, color: AppColor.inkMuted, fontFeatures: [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: Gap.xl),
              if (!_undone) ...[
                Text("${l.confirmationUndoHint} ($_secondsLeft s)", style: const TextStyle(color: AppColor.inkMuted)),
                const SizedBox(height: Gap.md),
                TextButton(onPressed: _undo, child: Text(l.actionUndo)),
              ],
              const SizedBox(height: Gap.lg),
              ElevatedButton(
                onPressed: () => context.go("/home"),
                child: Text(l.actionDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
