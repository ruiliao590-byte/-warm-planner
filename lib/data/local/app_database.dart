import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 本地数据库（sqflite）单例。
///
/// 表结构围绕两个生态的“打通”设计：task.goal_id 关联 goal，
/// 使“目标进度 = 已完成任务/总任务”可用一条 SQL 聚合算出；
/// record 独立存储，供 AI 排计划与复盘洞察读取。
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const int _version = 1;
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'warm_planner.db');
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'local',
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'short',
        description TEXT NOT NULL DEFAULT '',
        deadline INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'local',
        goal_id TEXT,
        title TEXT NOT NULL,
        date INTEGER NOT NULL,
        suggested_slot TEXT NOT NULL DEFAULT '',
        estimated_minutes INTEGER NOT NULL DEFAULT 30,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        reminder_time INTEGER,
        order_index INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_tasks_date ON tasks (date)');
    await db.execute('CREATE INDEX idx_tasks_goal ON tasks (goal_id)');

    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT 'local',
        type TEXT NOT NULL,
        situation TEXT NOT NULL DEFAULT '',
        problem TEXT NOT NULL DEFAULT '',
        analysis TEXT NOT NULL DEFAULT '',
        next_action TEXT NOT NULL DEFAULT '',
        idea TEXT NOT NULL DEFAULT '',
        trigger_context TEXT NOT NULL DEFAULT '',
        ai_suggestion TEXT NOT NULL DEFAULT '',
        tags TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_records_type ON records (type)');

    // 键值设置表（AI 配置、约束条件等以 JSON 字符串存储）
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// 【扩展点】未来加字段/表时在此写迁移脚本，version 递增。
  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // 目前仅 v1，后续版本在此按需迁移。
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
