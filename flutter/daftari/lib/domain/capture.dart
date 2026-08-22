import 'enums.dart';

/// Layer one: what the user actually said or typed.
///
/// Written once. Never edited, never deleted, including the parts the
/// interpreter did not understand. If an interpretation is ever wrong, the
/// original is still here.
final class Capture {
  const Capture({
    required this.id,
    required this.occurredAt,
    required this.verbatimText,
    required this.source,
    required this.languageCode,
    this.audioPath,
    this.syncedAt,
  });

  final String id;
  final DateTime occurredAt;
  final String verbatimText;
  final CaptureSource source;
  final String languageCode;
  final String? audioPath;

  /// Only field that ever changes after insert.
  final DateTime? syncedAt;

  bool get hasAudio => audioPath != null;

  bool get isSynced => syncedAt != null;
}
