import 'package:sqflite/sqflite.dart';

import '../models/record.dart';
import '../repositories/record_repository.dart';
import 'app_database.dart';

/// RecordRepository 的本地实现（sqflite）。
class LocalRecordRepository implements RecordRepository {
  final AppDatabase _appDb;
  LocalRecordRepository(this._appDb);

  Future<Database> get _db => _appDb.database;

  @override
  Future<List<RecordEntry>> getRecords({String? type}) async {
    final db = await _db;
    final rows = await db.query(
      'records',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'created_at DESC',
    );
    return rows.map(RecordEntry.fromMap).toList();
  }

  @override
  Future<RecordEntry?> getRecord(String id) async {
    final db = await _db;
    final rows = await db.query('records', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : RecordEntry.fromMap(rows.first);
  }

  @override
  Future<void> upsertRecord(RecordEntry record) async {
    final db = await _db;
    await db.insert('records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteRecord(String id) async {
    final db = await _db;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<RecordEntry>> getRecentRecords(DateTime since,
      {int limit = 30}) async {
    final db = await _db;
    final rows = await db.query(
      'records',
      where: 'created_at >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(RecordEntry.fromMap).toList();
  }
}
