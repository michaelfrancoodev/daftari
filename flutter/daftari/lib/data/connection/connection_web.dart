import "package:drift/drift.dart";
import "package:drift/wasm.dart";

/// Flutter Web: SQLite compiled to WebAssembly, since `dart:ffi` (used by
/// `connection_native.dart`) does not exist on this platform at all.
///
/// Depends on two static files in this project's `web/` folder:
///   - `sqlite3.wasm`  — the compiled SQLite WASM binary
///   - `drift_worker.js` — Drift's web-worker glue script
///
/// **Both files are checked into this repository** (`web/sqlite3.wasm`,
/// `web/drift_worker.js`), fetched directly from the official GitHub
/// Releases of `simolus3/sqlite3.dart` and `simolus3/drift` respectively —
/// see https://drift.simonbinder.eu/platforms/web/ for the canonical
/// source. Compatibility note (from Drift's maintainer): a `sqlite3.wasm`
/// build only requires the `sqlite3` Dart package version to be *at
/// least* the wasm's own version — this project's resolved `sqlite3`
/// package (3.5.2 as of this writing) satisfies that against the "latest"
/// release fetched here. If `pubspec.lock` is later regenerated against a
/// much older `sqlite3`/`drift` version, re-fetch matching assets from
/// the same two release pages instead of assuming these stay compatible
/// forever.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
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
  });
}
