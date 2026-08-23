import "package:drift/drift.dart";

/// Selected only if neither `dart.library.io` nor `dart.library.js_interop`
/// is true — i.e. never, on any platform Flutter actually supports. This
/// file exists purely so the conditional import in `database.dart` always
/// has a syntactically valid fallback target.
QueryExecutor openConnection() {
  throw UnsupportedError(
    "DAFTARI's database has no connection implementation for this platform. "
    "See lib/data/connection/ — native.dart covers Android/iOS/desktop, "
    "web.dart covers Flutter Web.",
  );
}
