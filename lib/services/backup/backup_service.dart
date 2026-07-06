import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../data/local/app_database.dart';

/// ============================================================
/// 云备份/恢复（第一版核心防丢手段）
/// 把全部数据序列化为一个 JSON；也能从 JSON 完整恢复。
/// 直接读写 sqflite 各表，保证“全量、可靠”。
/// ============================================================
class BackupService {
  final AppDatabase _appDb;
  BackupService(this._appDb);

  static const int schemaVersion = 1;
  static const List<String> _tables = ['goals', 'tasks', 'records', 'settings'];

  /// 导出：返回格式化的 JSON 字符串。
  Future<String> exportToJson() async {
    final db = await _appDb.database;
    final data = <String, dynamic>{
      'app': 'warm_planner',
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };
    for (final t in _tables) {
      data['tables'][t] = await db.query(t);
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 导入：用 JSON 覆盖恢复全部数据（先清空再写入，事务保证一致性）。
  /// 返回恢复的记录条数。
  Future<int> importFromJson(String jsonStr) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw const FormatException('文件不是有效的 JSON 备份。');
    }
    if (data['app'] != 'warm_planner' || data['tables'] is! Map) {
      throw const FormatException('这不是本 App 导出的备份文件。');
    }
    final tables = data['tables'] as Map<String, dynamic>;

    final db = await _appDb.database;
    int count = 0;
    await db.transaction((txn) async {
      // 顺序：先清空所有表（tasks 先于 goals，避免外键约束）
      await txn.delete('tasks');
      await txn.delete('records');
      await txn.delete('settings');
      await txn.delete('goals');

      // 先写 goals（tasks 外键依赖 goals）
      for (final t in _tables) {
        final rows = tables[t];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is! Map) continue;
          await txn.insert(t, Map<String, dynamic>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        }
      }
    });
    return count;
  }
}
