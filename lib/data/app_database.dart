import 'package:call_connect/core/app_constants.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';



class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _forcedPath = path;

  final DatabaseFactory? _factory;
  final String? _forcedPath;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final path = _forcedPath ??
        p.join(await getDatabasesPath(), AppConstants.dbName);

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE calls (
            call_id TEXT PRIMARY KEY NOT NULL,
            caller_id TEXT NOT NULL,
            callee_id TEXT NOT NULL,
            state TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            connected_at TEXT,
            ended_at TEXT,
            end_reason TEXT
          )
        ''');
        },
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
