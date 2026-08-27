# Known Limitations

## Flutter toolchain

Verified against a real Flutter installation: `flutter pub get`, `dart run build_runner build`, `flutter analyze` (clean), and `flutter test` (101/101 passing) all succeed. `flutter run` has been confirmed working on Android and web.

Two things worth knowing before shipping further:

- **Device sync is not built yet.** The app is fully functional offline; `lib/data/` has no client for the Cloud Run agents yet. Wiring `agents/sikio` and `agents/daftari` into a `sync_service.dart` is the natural next step once sync is needed.
- **Share-code linking between two parties** (e.g. a sponsor and a worker) is not built on-device yet, though `agents/mlinganishi` already supports reconciling two parties' records once it exists.
- **On-device app lock (PIN/biometric)** is intentionally not included. A lock on a phone with no account and no recovery path risks becoming the same "lost the notebook" failure this app exists to prevent; it will be added once cloud backup makes recovery possible.

## Agent fleet

All four Cloud Run agents (`agents/sikio`, `agents/daftari`, `agents/mkumbushi`, `agents/mlinganishi`) have working code, tests, and a Dockerfile. The deterministic logic in each (gap detection, reconciliation matching, validation) is fully unit-tested and passing. The Gemini-calling portions have correct, verified API usage but have not yet been run end-to-end against a live Gemini key, since deployment is the next step (see `docs/DEPLOYMENT.md`).

## Production readiness

- Release builds use debug signing until a real keystore is added — see the Flutter README's "Producing a signed release build" section.
- R8 minification is intentionally off for the release APK; several plugins here use native bindings that need verified keep rules first, and an oversized APK is a smaller problem than a silent runtime crash.
