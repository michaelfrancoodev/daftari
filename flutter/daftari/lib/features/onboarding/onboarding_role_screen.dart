import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../../app/providers.dart";
import "../../domain/enums.dart";
import "../../l10n/app_localizations.dart";
import "../../theme/tokens.dart";

/// Onboarding Screen 2 — Wewe ni Nani? (Role).
///
/// Four cards, one tap. The role decides which capture chips appear on
/// Home, which units are shown, and which destination sits fifth in the
/// bottom bar. Nothing beneath the surface changes, and it can be switched
/// later from Settings — so a first guess here never traps anyone.
class OnboardingRoleScreen extends StatelessWidget {
  const OnboardingRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = context.watch<SettingsController>();

    final roles = <(UserRole, IconData, String, String)>[
      (UserRole.miner, Icons.landscape_outlined, l.onboardingRoleMiner, l.onboardingRoleMinerDesc),
      (UserRole.sponsor, Icons.account_balance_wallet_outlined, l.onboardingRoleSponsor, l.onboardingRoleSponsorDesc),
      (UserRole.buyer, Icons.storefront_outlined, l.onboardingRoleBuyer, l.onboardingRoleBuyerDesc),
      (UserRole.trader, Icons.balance_outlined, l.onboardingRoleTrader, l.onboardingRoleTraderDesc),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: AppColor.ink),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                l.onboardingRoleTitle,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColor.ink),
              ),
              const SizedBox(height: Gap.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
                  itemBuilder: (context, i) {
                    final (role, icon, title, desc) = roles[i];
                    final selected = settings.role == role;
                    return InkWell(
                      onTap: () => settings.setRole(role),
                      borderRadius: BorderRadius.circular(Radii.md),
                      child: Container(
                        padding: const EdgeInsets.all(Gap.md),
                        decoration: BoxDecoration(
                          color: AppColor.surfaceRaised,
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(color: selected ? AppColor.ink : AppColor.line, width: selected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: AppColor.ink),
                            const SizedBox(width: Gap.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColor.ink)),
                                  Text(desc, style: const TextStyle(fontSize: 13, color: AppColor.inkMuted)),
                                ],
                              ),
                            ),
                            if (selected) const Icon(Icons.check_circle, color: AppColor.gold),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Text(
                l.onboardingRoleSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColor.inkMuted),
              ),
              const SizedBox(height: Gap.md),
              ElevatedButton(
                onPressed: () => context.go("/onboarding/promises"),
                child: Text(l.actionContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
