import 'package:sqflite/sqflite.dart';

import '../models/goal.dart';
import '../models/task.dart';
import '../repositories/plan_repository.dart';
import 'app_database.dart';

/// PlanRepository 的本地实现（sqflite）。
///
/// 核心亮点：getGoalsWithProgress 用一条 LEFT JOIN + 聚合 SQL 直接算出
/// 每个目标的“已完成任务数 / 总任务数”，可靠且高效——这是目标进度条
/// 自动累积的数据来源。
class LocalPlanRepository implements PlanRepository {
  final AppDatabase _appDb;
  LocalPlanRepository(this._appDb);

  Future<Database> get _db => _appDb.database;

  // ---------------- 目标 ----------------
  @override
  Future<List<Goal>> getGoals({bool includeCompleted = true}) async {
    final db = await _db;
    final rows = await db.query(
      'goals',
      where: includeCompleted ? null : 'is_completed = 0',
      orderBy: 'is_completed ASC, created_at DESC',
    );
    return rows.map(Goal.fromMap).toList();
  }

  @override
  Future<Goal?> getGoal(String id) async {
    final db = await _db;
    final rows = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Goal.fromMap(rows.first);
  }

  @override
  Future<void> upsertGoal(Goal goal) async {
    final db = await _db;
    await db.insert('goals', goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteGoal(String id) async {
    final db = await _db;
    // 外键 ON DELETE SET NULL：删除目标后其关联任务变为“无目标”，不丢任务。
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<GoalWithProgress>> getGoalsWithProgress(
      {bool includeCompleted = true}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT g.*,
             COUNT(t.id) AS total_tasks,
             COALESCE(SUM(t.is_completed), 0) AS completed_tasks
      FROM goals g
      LEFT JOIN tasks t ON t.goal_id = g.id
      ${includeCompleted ? '' : 'WHERE g.is_completed = 0'}
      GROUP BY g.id
      ORDER BY g.is_completed ASC, g.created_at DESC
    ''');
    return rows.map((r) {
      return GoalWithProgress(
        goal: Goal.fromMap(r),
        totalTasks: (r['total_tasks'] as int?) ?? 0,
        completedTasks: (r['completed_tasks'] as int?) ?? 0,
      );
    }).toList();
  }

  @override
  Future<GoalWithProgress?> getGoalWithProgress(String id) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT g.*,
             COUNT(t.id) AS total_tasks,
             COALESCE(SUM(t.is_completed), 0) AS completed_tasks
      FROM goals g
      LEFT JOIN tasks t ON t.goal_id = g.id
      WHERE g.id = ?
      GROUP BY g.id
    ''', [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return GoalWithProgress(
      goal: Goal.fromMap(r),
      totalTasks: (r['total_tasks'] as int?) ?? 0,
      completedTasks: (r['completed_tasks'] as int?) ?? 0,
    );
  }

  // ---------------- 任务 ----------------
  @override
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final db = await _db;
    final key = Task.dayKeyOf(date);
    final rows = await db.query(
      'tasks',
      where: 'date = ?',
      whereArgs: [key],
      orderBy: 'is_completed ASC, order_index ASC, created_at ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  @override
  Future<List<Task>> getTasksInRange(DateTime start, DateTime end) async {
    final db = await _db;
    final rows = await db.query(
      'tasks',
      where: 'date >= ? AND date <= ?',
      whereArgs: [Task.dayKeyOf(start), Task.dayKeyOf(end)],
      orderBy: 'date ASC, order_index ASC, created_at ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  @override
  Future<List<Task>> getTasksForGoal(String goalId) async {
    final db = await _db;
    final rows = await db.query('tasks',
        where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'date ASC');
    return rows.map(Task.fromMap).toList();
  }

  @override
  Future<void> upsertTask(Task task) async {
    final db = await _db;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> upsertTasks(List<Task> tasks) async {
    final db = await _db;
    final batch = db.batch();
    for (final t in tasks) {
      batch.insert('tasks', t.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> setTaskCompleted(String taskId, bool completed) async {
    final db = await _db;
    await db.update(
      'tasks',
      {
        'is_completed': completed ? 1 : 0,
        'completed_at':
            completed ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<({int total, int completed})> completionStats(
      DateTime start, DateTime end) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS total,
             COALESCE(SUM(is_completed), 0) AS completed
      FROM tasks
      WHERE date >= ? AND date <= ?
    ''', [Task.dayKeyOf(start), Task.dayKeyOf(end)]);
    final r = rows.first;
    return (
      total: (r['total'] as int?) ?? 0,
      completed: (r['completed'] as int?) ?? 0,
    );
  }
}
