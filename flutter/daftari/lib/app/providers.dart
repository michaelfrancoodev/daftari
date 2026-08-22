import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../domain/enums.dart";

/// App-wide settings: language and role, persisted locally. Nothing here
/// ever leaves the device — Onboarding Screen 3's promises are enforced by
/// this class having no network client at all.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _locale = Locale(_prefs.getString("locale") ?? "sw");
    _role = UserRole.values.asNameMap()[_prefs.getString("role")] ?? UserRole.miner;
    _onboarded = _prefs.getBool("onboarded") ?? false;
  }

  final SharedPreferences _prefs;

  Locale _locale = const Locale("sw");
  Locale get locale => _locale;
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs.setString("locale", locale.languageCode);
    notifyListeners();
  }

  /// The four roles share one engine; only labels, chips and the fifth
  /// navigation destination change. Default is [UserRole.miner] — the hero
  /// case 80% of design effort targets.
  UserRole _role = UserRole.miner;
  UserRole get role => _role;
  Future<void> setRole(UserRole role) async {
    _role = role;
    await _prefs.setString("role", role.name);
    notifyListeners();
  }

  bool _onboarded = false;
  bool get onboarded => _onboarded;
  Future<void> completeOnboarding() async {
    _onboarded = true;
    await _prefs.setBool("onboarded", true);
    notifyListeners();
  }

  Future<void> resetOnboardingForTesting() async {
    _onboarded = false;
    await _prefs.setBool("onboarded", false);
    notifyListeners();
  }
}

