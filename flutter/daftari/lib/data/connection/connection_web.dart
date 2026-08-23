import "package:drift/drift.dart";
import "package:drift/wasm.dart";

/// Flutter Web: SQLite compiled to WebAssembly, since `dart:ffi` (used by
/// `connection_native.dart`) does not exist on this platform at all.
///
/// **Setup required before this works:** two static files must be present
/// in this project's `web/` folder:
///   - `sqlite3.wasm`  — the compiled SQLite WASM binary
///   - `drift_worker.js` — Drift's web-worker glue script
///
/// Neither file is checked into this repository, because they are binary
/// build artifacts tied to the exact `sqlite3` and `drift` package
/// versions in `pubspec.yaml` (currently sqlite3 3.5.2, drift 2.34.3) —
/// committing a stale copy would be worse than not committing one. Follow
/// Drift's current official web setup guide to obtain the matching pair
/// for your installed versions: https://drift.simonbinder.eu/platforms/web/
///
/// Until those two files are in place, this throws instead of silently
/// producing a broken database — see the message below for exactly what's
/// missing. The Android build (`connection_native.dart`) does not need
/// this step at all.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    try {
      final result = await WasmDatabase.open(
        databaseName: "daftari",
        sqlite3Uri: Uri.parse("sqlite3.wasm"),
        driftWorkerUri: Uri.parse("drift_worker.js"),
      );

      if (result.missingFeatures.isNotEmpty) {
        // Not fatal — Drift falls back to the best available storage
        // (e.g. IndexedDB instead of OPFS) automatically. Logged so a
        // developer can see which browser feature was unavailable.
        // ignore: avoid_print
        print("DAFTARI (web database): using ${result.chosenImplementation}, "
            "missing: ${result.missingFeatures}");
      }

      return result.resolvedExecutor;
    } catch (e) {
      throw StateError(
        "DAFTARI's web database could not start. This almost always means "
        "web/sqlite3.wasm and web/drift_worker.js are missing — see the "
        "doc comment at the top of connection_web.dart for where to get "
        "them. Original error: $e",
      );
    }
  });
}
