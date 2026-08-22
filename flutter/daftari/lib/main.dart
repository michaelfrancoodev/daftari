import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "app/app.dart";
import "app/providers.dart";
import "data/database.dart";
import "data/ledger_repository.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  final ledgerRepository = LedgerRepository(db);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<LedgerRepository>.value(value: ledgerRepository),
        ChangeNotifierProvider(create: (_) => SettingsController(prefs)),
      ],
      child: const DaftariApp(),
    ),
  );
}
