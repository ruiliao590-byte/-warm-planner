import '../models/goal.dart';
import '../models/task.dart';

/// ============================================================
/// 计划仓库【抽象接口】——业务逻辑只依赖它，不直接碰数据库。
///
/// 第一版：LocalPlanRepository（sqflite 本地实现）。
/// 【扩展点·上云】未来做云端实时同步时，新增 CloudPlanRepository
/// 实现同一接口，在 providers 里替换绑定即可，业务代码零改动。
/// ============================================================
abstract class PlanRepository {
  // ---- 目标 ----
  Future<List<Goal>> getGoals({bool includeCompleted = true});
  Future<Goal?> getGoal(String id);
  Future<void> upsertGoal(Goal goal);
  Future<void> deleteGoal(String id);

  /// 目标 + 自动计算的进度（进度 = 已完成任务数 / 计划任务总数）
  Future<List<GoalWithProgress>> getGoalsWithProgress(
      {bool includeCompleted = true});
  Future<GoalWithProgress?> getGoalWithProgress(String id);

  // ---- 任务 ----
  Future<List<Task>> getTasksForDate(DateTime date);
  Future<List<Task>> getTasksInRange(DateTime start, DateTime end);
  Future<List<Task>> getTasksForGoal(String goalId);
  Future<void> upsertTask(Task task);
  Future<void> upsertTasks(List<Task> tasks);
  Future<void> deleteTask(String id);

  /// 勾选/取消打卡——完成时记录完成时间。
  Future<void> setTaskCompleted(String taskId, bool completed);

  /// 近期完成情况摘要（喂给 AI 排计划/洞察）：返回区间内任务总数与完成数。
  Future<({int total, int completed})> completionStats(
      DateTime start, DateTime end);
}
