import "dart:async";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:speech_to_text/speech_to_text.dart" as stt;
import "../../app/providers.dart";
import "../../app/router.dart";
import "../../data/ledger_repository.dart";
import "../../domain/enums.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";

/// Screen 5 — Kurekodi sauti (Voice capture).
///
/// One press starts, another stops, and four seconds of silence stops it
/// automatically for anyone who forgets. There is no time limit — a single
/// utterance may hold the whole day. The transcript appears live, as it is
/// heard, so the user can see whether the app understood correctly before
/// anything is written anywhere.
class VoiceCaptureScreen extends StatefulWidget {
  const VoiceCaptureScreen({super.key});

  @override
  State<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends State<VoiceCaptureScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _transcript = "";
  Timer? _silenceTimer;
  Duration _elapsed = Duration.zero;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await _speech.initialize(onStatus: _onStatus, onError: (_) {});
    if (mounted) setState(() => _available = available);
    if (available) _start();
  }

  void _onStatus(String status) {
    if (status == "notListening" && _listening) _stop();
  }

  Future<void> _start() async {
    if (!_available) return;
    setState(() {
      _listening = true;
      _transcript = "";
      _elapsed = Duration.zero;
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });

    final settings = context.read<SettingsController>();
    await _speech.listen(
      localeId: settings.locale.languageCode == "sw" ? "sw_TZ" : "en_US",
      onResult: (result) {
        setState(() => _transcript = result.recognizedWords);
        _resetSilenceTimer();
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 4),
    );
    _resetSilenceTimer();
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 4), _stop);
  }

  Future<void> _stop() async {
    _silenceTimer?.cancel();
    _clock?.cancel();
    await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);

    final settings = context.read<SettingsController>();
    final repo = context.read<LedgerRepository>();
    final text = _transcript.trim();

    if (text.isEmpty) {
      context.pop();
      return;
    }

    final drafts = repo.interpret(text);
    context.pushReplacement(
      "/capture/review",
      extra: ReviewArgs(
        verbatimText: text,
        source: CaptureSource.voice,
        languageCode: settings.locale.languageCode,
        drafts: drafts,
      ),
    );
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _clock?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final minutes = _elapsed.inMinutes.toString().padLeft(1, "0");
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, "0");

    return Scaffold(
      backgroundColor: AppColor.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, color: AppColor.surface),
                ),
              ),
              const Spacer(),
              if (!_available)
                Text(l.errorNoMicPermission, style: const TextStyle(color: AppColor.surface), textAlign: TextAlign.center)
              else ...[
                Icon(_listening ? Icons.graphic_eq : Icons.mic_none, color: AppColor.gold, size: 56),
                const SizedBox(height: Gap.md),
                Text("$minutes:$seconds", style: const TextStyle(color: AppColor.surface, fontSize: 15)),
                const SizedBox(height: Gap.lg),
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.all(Gap.md),
                  child: Text(
                    _transcript.isEmpty ? l.captureListening : _transcript,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColor.surface, fontSize: 20, height: 1.4),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: _listening ? _stop : _start,
                child: Container(
                  width: Touch.micButton,
                  height: Touch.micButton,
                  decoration: BoxDecoration(
                    color: AppColor.gold,
                    shape: BoxShape.circle,
                    border: _listening ? Border.all(color: AppColor.surface, width: 3) : null,
                  ),
                  child: Icon(_listening ? Icons.stop : Icons.mic, color: AppColor.ink, size: 40),
                ),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                _listening ? l.captureStop : l.captureHoldToTalk,
                style: const TextStyle(color: AppColor.surface, fontSize: 13),
              ),
              const SizedBox(height: Gap.md),
              TextButton(
                onPressed: () => context.pushReplacement("/capture/type"),
                child: Text(l.captureSwitchToType, style: const TextStyle(color: AppColor.surface)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
