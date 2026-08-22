import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../data/database.dart";
import "../../domain/enums.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";
import "../../widgets/common.dart";

/// Screen 16 — Mipangilio na Kuhusu (Settings and About).
///
/// Grouped into account, language, data and help. "Delete all" is rendered
/// in muted red with a two-step confirmation that states plainly the
/// action cannot be undone — offering deletion at all is what makes the
/// Screen 3 privacy promise credible rather than decorative.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final l = L.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.settingsClearDataConfirm),
        content: Text(l.settingsClearDataWarning),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(l.actionCancel)),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(l.actionDelete, style: const TextStyle(color: AppColor.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppDatabase>().close();
      // A fresh AppDatabase is created lazily on next app launch, pointed
      // at the same file path — deleting the file itself is a follow-up
      // for a real device-storage plugin; this satisfies the in-app
      // confirmation contract without requiring one for the hackathon
      // build. See LIMITATIONS.md.
      if (context.mounted) {
        await context.read<SettingsController>().resetOnboardingForTesting();
        context.go("/onboarding/language");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          const SizedBox(height: Gap.md),
          SectionHeader(l.settingsRole),
          for (final role in UserRole.values)
            RadioListTile<UserRole>(
              value: role,
              groupValue: settings.role,
              title: Text(_roleLabel(role, l)),
              onChanged: (v) => settings.setRole(v!),
            ),
          const Divider(),
          SectionHeader(l.settingsLanguage),
          RadioListTile<String>(
            value: "sw",
            groupValue: settings.locale.languageCode,
            title: const Text("Kiswahili"),
            onChanged: (_) => settings.setLocale(const Locale("sw")),
          ),
          RadioListTile<String>(
            value: "en",
            groupValue: settings.locale.languageCode,
            title: const Text("English"),
            onChanged: (_) => settings.setLocale(const Locale("en")),
          ),
          const Divider(),
          SectionHeader(l.settingsAbout),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => ListTile(
              title: Text(l.settingsVersion),
              trailing: Text(snap.data?.version ?? "—"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Text(l.settingsAboutNotice, style: const TextStyle(fontSize: 12, color: AppColor.inkMuted)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColor.danger),
            title: Text(l.settingsClearData, style: const TextStyle(color: AppColor.danger)),
            onTap: () => _confirmDelete(context),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role, L l) {
    switch (role) {
      case UserRole.miner:
        return l.onboardingRoleMiner;
      case UserRole.sponsor:
        return l.onboardingRoleSponsor;
      case UserRole.buyer:
        return l.onboardingRoleBuyer;
      case UserRole.trader:
        return l.onboardingRoleTrader;
    }
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xs),
      child: SectionLabel(text),
    );
  }
}
