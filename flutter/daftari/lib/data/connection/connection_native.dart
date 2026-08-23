import "dart:io";
import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

/// Android, iOS, and desktop: a real SQLite file via `dart:ffi`, which is
/// only available on these platforms — never on Flutter Web (see
/// `connection_web.dart`, selected instead there by `database.dart`'s
/// conditional import).
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, "daftari.sqlite"));
    return NativeDatabase.createInBackground(file);
  });
}
