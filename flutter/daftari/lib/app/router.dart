import "package:go_router/go_router.dart";
import "../domain/capture.dart";
import "../domain/entry.dart";
import "../domain/enums.dart";
import "../domain/interpreter.dart";
import "../features/onboarding/onboarding_language_screen.dart";
import "../features/onboarding/onboarding_role_screen.dart";
import "../features/onboarding/onboarding_promises_screen.dart";
import "../features/home/home_screen.dart";
import "../features/capture/voice_capture_screen.dart";
import "../features/capture/typed_capture_screen.dart";
import "../features/capture/quick_capture_screen.dart";
import "../features/capture/review_screen.dart";
import "../features/capture/confirmation_screen.dart";
import "../features/batch/batch_screen.dart";
import "../features/presale/presale_screen.dart";
import "../features/inbox/inbox_screen.dart";
import "../features/day/day_report_screen.dart";
import "../features/day/origin_screen.dart";
import "../features/report/month_report_screen.dart";
import "../features/settings/settings_screen.dart";
import "../features/splash/splash_screen.dart";
import "providers.dart";

GoRouter buildRouter(SettingsController settings) {
  return GoRouter(
    initialLocation: "/",
    refreshListenable: settings,
    redirect: (context, state) {
      final onboarding = state.matchedLocation.startsWith("/onboarding");
      final splash = state.matchedLocation == "/";
      if (!settings.onboarded && !onboarding && !splash) {
        return "/onboarding/language";
      }
      if (settings.onboarded && (onboarding || splash)) {
        return "/home";
      }
      return null;
    },
    routes: [
      GoRoute(path: "/", builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: "/onboarding/language",
        builder: (context, state) => const OnboardingLanguageScreen(),
      ),
      GoRoute(
        path: "/onboarding/role",
        builder: (context, state) => const OnboardingRoleScreen(),
      ),
      GoRoute(
        path: "/onboarding/promises",
        builder: (context, state) => const OnboardingPromisesScreen(),
      ),
      GoRoute(path: "/home", builder: (context, state) => const HomeScreen()),
      GoRoute(path: "/capture/voice", builder: (context, state) => const VoiceCaptureScreen()),
      GoRoute(path: "/capture/type", builder: (context, state) => const TypedCaptureScreen()),
      GoRoute(
        path: "/capture/quick",
        builder: (context, state) => QuickCaptureScreen(initialKind: state.extra as EntryKind?),
      ),
      GoRoute(
        path: "/capture/review",
        builder: (context, state) => ReviewScreen(args: state.extra as ReviewArgs),
      ),
      GoRoute(
        path: "/capture/confirmation",
        builder: (context, state) => ConfirmationScreen(result: state.extra as ConfirmationArgs),
      ),
      GoRoute(path: "/batch", builder: (context, state) => const BatchScreen()),
      GoRoute(path: "/presale", builder: (context, state) => const PresaleScreen()),
      GoRoute(path: "/inbox", builder: (context, state) => const InboxScreen()),
      GoRoute(path: "/day-report", builder: (context, state) => const DayReportScreen()),
      GoRoute(
        path: "/origin/:captureId",
        builder: (context, state) => OriginScreen(captureId: state.pathParameters["captureId"]!),
      ),
      GoRoute(path: "/month-report", builder: (context, state) => const MonthReportScreen()),
      GoRoute(path: "/settings", builder: (context, state) => const SettingsScreen()),
    ],
  );
}

/// Carried from a capture screen to the Review screen (Screen 8). Nothing
/// is written to the ledger until the person on Review agrees — Rule #1.
class ReviewArgs {
  const ReviewArgs({
    required this.verbatimText,
    required this.source,
    required this.languageCode,
    required this.drafts,
    this.audioPath,
  });

  final String verbatimText;
  final CaptureSource source;
  final String languageCode;
  final List<DraftEntry> drafts;
  final String? audioPath;
}

/// Carried from Review to the Confirmation sheet (Screen 9) once a commit
/// has actually been written.
class ConfirmationArgs {
  const ConfirmationArgs({required this.capture, required this.entries});

  final Capture capture;
  final List<Entry> entries;
}
