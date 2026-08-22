import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../theme/tokens.dart";

class OnboardingLanguageScreen extends StatelessWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Gap.xxl),
              const Text(
                "Chagua Lugha",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColor.ink),
              ),
              const Text(
                "Choose a Language",
                style: TextStyle(fontSize: 16, color: AppColor.inkMuted),
              ),
              const SizedBox(height: Gap.xxl),
              _LanguageOption(
                label: "Kiswahili",
                selected: settings.locale.languageCode == "sw",
                onTap: () => settings.setLocale(const Locale("sw")),
              ),
              const SizedBox(height: Gap.md),
              _LanguageOption(
                label: "English",
                selected: settings.locale.languageCode == "en",
                onTap: () => settings.setLocale(const Locale("en")),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go("/onboarding/role"),
                child: const Text("Endelea / Continue"),
              ),
              const SizedBox(height: Gap.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        width: double.infinity,
        height: Touch.min,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        decoration: BoxDecoration(
          color: selected ? AppColor.ink : AppColor.surfaceRaised,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: selected ? AppColor.ink : AppColor.line, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColor.surface : AppColor.ink,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColor.gold),
          ],
        ),
      ),
    );
  }
}
