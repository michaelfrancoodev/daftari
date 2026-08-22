import 'package:flutter/widgets.dart';

/// Design tokens.
///
/// Two colours carry the entire interface. Navy is everything structural;
/// gold marks exactly one action per screen. A third accent would dilute
/// that signal, so status colours appear only as small dots and are always
/// accompanied by words — colour alone fails in bright sunlight and for
/// colour-blind users, both of which are the norm here rather than the edge.
abstract final class AppColor {
  /// Page background. Off-white rather than pure white: less glare outdoors.
  static const Color surface = Color(0xFFFCFCFA);

  /// Raised surfaces such as cards and sheets.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// Primary ink: text, outlines, structure.
  static const Color ink = Color(0xFF0B1B2B);

  /// Secondary text and labels.
  static const Color inkMuted = Color(0xFF5B6B7A);

  /// Hairlines and dividers.
  static const Color line = Color(0xFFE2E6EA);

  /// The single accent. Reserved for the primary action on a screen.
  static const Color gold = Color(0xFFE8A317);

  /// Status dots. Never used alone; always paired with text.
  static const Color fresh = Color(0xFF2E7D4F);
  static const Color ageing = Color(0xFFC98A0B);
  static const Color stale = Color(0xFFB3261E);

  /// Destructive actions only.
  static const Color danger = Color(0xFFB3261E);
}

/// Spacing scale. Every gap in the app is one of these values.
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Interactive sizing.
///
/// Well above the 48dp platform guidance, because these are working hands —
/// often wet or dusty, on a phone held one-handed at a pit.
abstract final class Touch {
  static const double min = 56;
  static const double micButton = 96;
}

/// Motion.
///
/// Deliberately brief. Animation is confirmation, not decoration, and long
/// transitions feel sluggish on the low-end hardware this ships to.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// How long the undo affordance stays live after a capture.
  static const Duration undoWindow = Duration(seconds: 3);
}
