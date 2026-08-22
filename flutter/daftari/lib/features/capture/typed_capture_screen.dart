import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../app/router.dart";
import "../../data/ledger_repository.dart";
import "../../domain/enums.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";

/// Screen 6 — Kuandika (Typing).
///
/// Typing is not a lesser path, it is the same path: one open box, no
/// form, no field to complete. The interpreter that reads a spoken
/// sentence reads a typed one identically.
class TypedCaptureScreen extends StatefulWidget {
  const TypedCaptureScreen({super.key});

  @override
  State<TypedCaptureScreen> createState() => _TypedCaptureScreenState();
}

class _TypedCaptureScreenState extends State<TypedCaptureScreen> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final settings = context.read<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final drafts = repo.interpret(text);

    context.pushReplacement(
      "/capture/review",
      extra: ReviewArgs(
        verbatimText: text,
        source: CaptureSource.typed,
        languageCode: settings.locale.languageCode,
        drafts: drafts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none),
            tooltip: l.captureSwitchToVoice,
            onPressed: () => context.pushReplacement("/capture/voice"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 20, height: 1.5),
                decoration: InputDecoration(
                  hintText: l.captureTypedPlaceholder,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            ElevatedButton(onPressed: _submit, child: Text(l.actionContinue)),
          ],
        ),
      ),
    );
  }
}
