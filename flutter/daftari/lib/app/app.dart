import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "../l10n/app_localizations.dart";
import "../theme/app_theme.dart";
import "providers.dart";
import "router.dart";

class DaftariApp extends StatefulWidget {
  const DaftariApp({super.key});

  @override
  State<DaftariApp> createState() => _DaftariAppState();
}

class _DaftariAppState extends State<DaftariApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _router = buildRouter(settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return MaterialApp.router(
      title: "DAFTARI",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: settings.locale,
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
