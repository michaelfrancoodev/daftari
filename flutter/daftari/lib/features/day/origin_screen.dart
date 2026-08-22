import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../data/ledger_repository.dart";
import "../../domain/capture.dart";
import "../../domain/entry.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 14 — Chanzo (Origin).
///
/// Layer 1 made visible: the whole sentence, exactly as spoken, never
/// edited. Every entry below it points back to the words that produced it
/// — Rule #3 and Rule #4 made concrete on one screen.
class OriginScreen extends StatelessWidget {
  const OriginScreen({super.key, required this.captureId});

  final String captureId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final locale = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l.originTitle)),
      body: FutureBuilder<Capture?>(
        future: repo.captureById(captureId),
        builder: (context, captureSnap) {
          final capture = captureSnap.data;
          if (capture == null) return const SizedBox.shrink();

          return FutureBuilder<List<Entry>>(
            future: repo.entriesForCapture(captureId),
            builder: (context, entriesSnap) {
              final entries = entriesSnap.data ?? const <Entry>[];
              return ListView(
                padding: const EdgeInsets.all(Gap.lg),
                children: [
                  SectionLabel(l.originVerbatim),
                  const SizedBox(height: Gap.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Gap.md),
                    decoration: BoxDecoration(color: AppColor.surfaceRaised, borderRadius: BorderRadius.circular(Radii.md), border: Border.all(color: AppColor.line)),
                    child: Text(capture.verbatimText, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16, height: 1.5)),
                  ),
                  if (capture.audioPath != null) ...[
                    const SizedBox(height: Gap.sm),
                    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.play_arrow), label: Text(l.originPlayAudio)),
                  ],
                  const SizedBox(height: Gap.xl),
                  SectionLabel(l.originEntriesFromThisCapture),
                  const SizedBox(height: Gap.sm),
                  for (final e in entries)
                    Card(
                      child: ListTile(
                        title: Text(e.sourceSpan ?? e.kind.name),
                        subtitle: Text(
                          e.amount != null ? formatMoney(e.amount!, locale) : e.quantity != null ? "${e.quantity} ${l.unitGrams}" : "—",
                        ),
                        trailing: e.isSettled ? const Icon(Icons.check_circle, color: AppColor.fresh) : const Icon(Icons.help_outline, color: AppColor.gold),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
