import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import 'app_database.dart';

/// SettingsRepository 的本地实现（sqflite 的 settings KV 表）。
class LocalSettingsRepository implements SettingsRepository {
  final AppDatabase _appDb;
  LocalSettingsRepository(this._appDb);

  Future<Database> get _db => _appDb.database;

  static const _kAiConfig = 'ai_config';
  static const _kConstraints = 'user_constraints';

  @override
  Future<String?> getRaw(String key) async {
    final db = await _db;
    final rows =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  @override
  Future<void> setRaw(String key, String value) async {
    final db = await _db;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<AiConfig> getAiConfig() async {
    final raw = await getRaw(_kAiConfig);
    if (raw == null) return const AiConfig();
    return AiConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveAiConfig(AiConfig config) async {
    await setRaw(_kAiConfig, jsonEncode(config.toJson()));
  }

  @override
  Future<UserConstraints> getConstraints() async {
    final raw = await getRaw(_kConstraints);
    if (raw == null) return const UserConstraints();
    return UserConstraints.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveConstraints(UserConstraints constraints) async {
    await setRaw(_kConstraints, jsonEncode(constraints.toJson()));
  }
}
