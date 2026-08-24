import 'package:call_connect/model/call_data_model.dart';
import 'package:call_connect/model/call_state.dart';
import 'package:sqflite/sqflite.dart';


import 'app_database.dart';

class CallRepository {
  CallRepository(this._appDb);

  final AppDatabase _appDb;

  Future<Database> get _db => _appDb.database;

  Future<bool> insertIfAbsent(CallDataModel call) async {
    final existing = await getById(call.callId);
    if (existing != null) return false;

    final db = await _db;
    final rowId = await db.insert(
      'calls',
      call.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return rowId > 0;
  }

  Future<CallDataModel?> getById(String callId) async {
    final db = await _db;
    final rows = await db.query(
      'calls',
      where: 'call_id = ?',
      whereArgs: [callId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CallDataModel.fromMap(rows.first);
  }

  Future<CallDataModel?> getActiveCall() async {
    final db = await _db;
    final activeNames = CallState.values
        .where((s) => s.isActive)
        .map((s) => s.name)
        .toList();
    final placeholders = List.filled(activeNames.length, '?').join(',');
    final rows = await db.query(
      'calls',
      where: 'state IN ($placeholders)',
      whereArgs: activeNames,
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CallDataModel.fromMap(rows.first);
  }

  Future<List<CallDataModel>> getHistory({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'calls',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(CallDataModel.fromMap).toList();
  }

  Future<CallDataModel?> updateState(
    String callId,
    CallState next, {
    String? endReason,
  }) async {
    final current = await getById(callId);
    if (current == null) return null;

    final resolved = CallStateMachine.tryTransition(current.state, next);
    if (resolved == null) return null;
    if (resolved == current.state) return current; // same-state no-op

    final now = DateTime.now();
    var updated = current.copyWith(state: resolved, updatedAt: now);

    if (resolved == CallState.connected) {
      updated = updated.copyWith(connectedAt: now);
    }
    if (resolved.isTerminal) {
      updated = updated.copyWith(endedAt: now, endReason: endReason);
    }

    final db = await _db;
    await db.update(
      'calls',
      updated.toMap(),
      where: 'call_id = ?',
      whereArgs: [callId],
    );
    return updated;
  }

 
}
