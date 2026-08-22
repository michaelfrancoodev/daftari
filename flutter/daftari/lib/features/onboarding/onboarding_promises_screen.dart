import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";

/// Onboarding Screen 3 — Daftari lako ni lako (Trust).
///
/// Shown once. Four concrete promises, no paragraph — each one is a real
/// constraint the product was designed around, which is why it can be
/// stated this plainly.
class OnboardingPromisesScreen extends StatelessWidget {
  const OnboardingPromisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.read<SettingsController>();
    final promises = [l.onboardingPromise1, l.onboardingPromise2, l.onboardingPromise3, l.onboardingPromise4];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Gap.xxl),
              Text(
                l.onboardingPromisesTitle,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColor.ink),
              ),
              const SizedBox(height: Gap.xl),
              ...promises.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: Gap.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, color: AppColor.gold),
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Text(p, style: const TextStyle(fontSize: 17, color: AppColor.ink)),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await settings.completeOnboarding();
                  if (context.mounted) context.go("/home");
                },
                child: Text(l.onboardingPromisesCta),
              ),
              const SizedBox(height: Gap.lg),
            ],
          ),
        ),
      ),
    );
  }
}
