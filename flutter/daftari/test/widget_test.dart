// A basic widget-level smoke test for the shared, dependency-light pieces
// in `widgets/common.dart`. The default `flutter create` template this
// file used to contain (a counter-app test referencing a non-existent
// `MyApp` class) never matched this project and always failed; the tests
// below actually exercise DAFTARI code.
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:daftari/widgets/common.dart";
import "package:daftari/theme/tokens.dart";

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group("StatusDot", () {
    testWidgets("renders its label text", (tester) async {
      await tester.pumpWidget(_wrap(const StatusDot(color: AppColor.fresh, label: "Leo, 12 Agosti")));
      expect(find.text("Leo, 12 Agosti"), findsOneWidget);
    });

    testWidgets("colour is never the only signal — a label is always present", (tester) async {
      // Screen rule #3 in the master specification: every status dot must
      // carry text beside it.
      await tester.pumpWidget(_wrap(const StatusDot(color: AppColor.stale, label: "Siku 4 zilizopita")));
      expect(find.byType(Text), findsWidgets);
      expect(find.text("Siku 4 zilizopita"), findsOneWidget);
    });
  });

  group("FigureRow", () {
    testWidgets("shows both the label and the value", (tester) async {
      await tester.pumpWidget(_wrap(const FigureRow(label: "Jumla", value: "615,000")));
      expect(find.text("Jumla"), findsOneWidget);
      expect(find.text("615,000"), findsOneWidget);
    });

    testWidgets("shows a chevron only when tappable, per screen rule #7", (tester) async {
      await tester.pumpWidget(_wrap(FigureRow(label: "Mawe", value: "500,000", onTap: () {})));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets("shows no chevron when there is nothing to expand into", (tester) async {
      await tester.pumpWidget(_wrap(const FigureRow(label: "Mawe", value: "500,000")));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets("an emphasised row is still readable as plain text", (tester) async {
      await tester.pumpWidget(_wrap(const FigureRow(label: "Kwa Gramu", value: "146,429", emphasize: true)));
      expect(find.text("146,429"), findsOneWidget);
    });
  });
}
