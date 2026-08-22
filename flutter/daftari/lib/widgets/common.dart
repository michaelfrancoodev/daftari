import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../core/money.dart";
import "../domain/enums.dart";
import "../l10n/app_localizations.dart";
import "../theme/tokens.dart";

/// A status dot that always carries words beside it — colour alone fails
/// in bright sunlight and for colour-blind users (Rule #7, screen rule #3).
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: Gap.sm),
        Text(label, style: const TextStyle(color: AppColor.inkMuted, fontSize: 13)),
      ],
    );
  }
}

/// Formats a [Money] value with tabular figures for the given locale.
String formatMoney(Money money, String localeCode) => money.format(locale: localeCode);

/// A small uppercase kicker label used above section headings throughout
/// the reports and settings screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColor.inkMuted,
      ),
    );
  }
}

/// A simple labelled row used across batch, day and month reports — a
/// figure on the right, its label on the left, tabular so columns align.
class FigureRow extends StatelessWidget {
  const FigureRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool emphasize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 16 : 14,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              color: emphasize ? AppColor.ink : AppColor.inkMuted,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: emphasize ? 18 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColor.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: Gap.xs),
                const Icon(Icons.chevron_right, size: 18, color: AppColor.inkMuted),
              ],
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// The five fixed bottom-navigation destinations shared by every core
/// screen. The fifth destination changes with role: Debts for a sponsor,
/// Purchases for a buyer, otherwise More.
class DaftariBottomNav extends StatelessWidget {
  const DaftariBottomNav({super.key, required this.currentIndex, required this.role});

  final int currentIndex;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: l.navHome),
        BottomNavigationBarItem(icon: const Icon(Icons.edit_outlined), label: l.navWrite),
        BottomNavigationBarItem(icon: const Icon(Icons.forum_outlined), label: l.navQuestions),
        BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_outlined), label: l.navReports),
        BottomNavigationBarItem(icon: const Icon(Icons.more_horiz), label: l.navMore),
      ],
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go("/home");
        break;
      case 1:
        context.go("/capture/voice");
        break;
      case 2:
        context.go("/inbox");
        break;
      case 3:
        context.go("/month-report");
        break;
      case 4:
        context.go("/settings");
        break;
    }
  }
}

/// The eight universal capture chips, relabelled per role. Order matches
/// the master specification's Home screen mockup.
List<({EntryKind kind, String label})> chipsForRole(UserRole role, L l) {
  final String ore = role == UserRole.trader ? l.chipStock : l.chipOre;
  final String fuel = role == UserRole.trader ? l.chipPower : l.chipFuel;
  return [
    (kind: EntryKind.orePurchase, label: ore),
    (kind: EntryKind.fuel, label: fuel),
    (kind: EntryKind.milling, label: l.chipMilling),
    (kind: EntryKind.goldYield, label: l.chipYield),
    (kind: EntryKind.wages, label: l.chipWages),
    (kind: EntryKind.loan, label: role == UserRole.sponsor ? l.chipAdvance : l.chipLoan),
    (kind: EntryKind.repayment, label: role == UserRole.sponsor ? l.chipRepaymentReceived : l.chipRepayment),
    (kind: EntryKind.sale, label: role == UserRole.buyer ? l.chipPurchase : l.chipSale),
  ];
}
