import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/local_plan_repository.dart';
import '../data/local/local_record_repository.dart';
import '../data/local/local_settings_repository.dart';
import '../data/models/app_settings.dart';
import '../data/models/goal.dart';
import '../data/models/record.dart';
import '../data/models/task.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../services/ai/ai_planner.dart';
import '../services/ai/deepseek_service.dart';
import '../services/backup/backup_service.dart';

/// ============================================================
/// 依赖注入总线（Riverpod）
///
/// 【扩展点·上云 —— 唯一改动点】
/// 未来要接云端实时同步时，只需把下面三个 Repository provider 的返回值
/// 从 Local*** 换成 Cloud***（实现同一接口），全 App 业务/UI 代码零改动。
/// ============================================================

final _databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

// ---- Repository 接口 → 本地实现（未来在此替换为云端实现）----
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return LocalPlanRepository(ref.watch(_databaseProvider));
});

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return LocalRecordRepository(ref.watch(_databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository(ref.watch(_databaseProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(_databaseProvider));
});

// ---- AI 配置 / 约束条件（可写状态）----
final aiConfigProvider =
    AsyncNotifierProvider<AiConfigNotifier, AiConfig>(AiConfigNotifier.new);

class AiConfigNotifier extends AsyncNotifier<AiConfig> {
  @override
  Future<AiConfig> build() =>
      ref.watch(settingsRepositoryProvider).getAiConfig();

  Future<void> save(AiConfig config) async {
    await ref.read(settingsRepositoryProvider).saveAiConfig(config);
    state = AsyncData(config);
  }
}

final constraintsProvider =
    AsyncNotifierProvider<ConstraintsNotifier, UserConstraints>(
        ConstraintsNotifier.new);

class ConstraintsNotifier extends AsyncNotifier<UserConstraints> {
  @override
  Future<UserConstraints> build() =>
      ref.watch(settingsRepositoryProvider).getConstraints();

  Future<void> save(UserConstraints c) async {
    await ref.read(settingsRepositoryProvider).saveConstraints(c);
    state = AsyncData(c);
  }
}

// ---- AI Service / Planner（随配置变化重建）----
final deepSeekServiceProvider = Provider<DeepSeekService?>((ref) {
  final config = ref.watch(aiConfigProvider).valueOrNull;
  if (config == null) return null;
  return DeepSeekService(config);
});

final aiPlannerProvider = Provider<AiPlanner?>((ref) {
  final service = ref.watch(deepSeekServiceProvider);
  if (service == null) return null;
  return AiPlanner(service);
});

/// 是否已配置 AI（UI 用来给未配置友好提示）
final aiConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(aiConfigProvider).valueOrNull?.isConfigured ?? false;
});

// ============================================================
// 业务数据 Providers
// ============================================================

/// 当前选中的“今日”日期（默认今天，可用于查看其他天）
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 某天的任务列表
final tasksForDateProvider =
    FutureProvider.family<List<Task>, DateTime>((ref, date) async {
  // 依赖刷新信号：任一任务变更后自增，触发重查
  ref.watch(planRefreshProvider);
  return ref.watch(planRepositoryProvider).getTasksForDate(date);
});

/// 今日任务（跟随 selectedDate）
final todayTasksProvider = FutureProvider<List<Task>>((ref) async {
  final date = ref.watch(selectedDateProvider);
  ref.watch(planRefreshProvider);
  return ref.watch(planRepositoryProvider).getTasksForDate(date);
});

/// 目标 + 进度列表
final goalsWithProgressProvider =
    FutureProvider<List<GoalWithProgress>>((ref) async {
  ref.watch(planRefreshProvider);
  return ref.watch(planRepositoryProvider).getGoalsWithProgress();
});

/// 记录列表（按类型筛选，null=全部）
final recordsProvider =
    FutureProvider.family<List<RecordEntry>, String?>((ref, type) async {
  ref.watch(recordRefreshProvider);
  return ref.watch(recordRepositoryProvider).getRecords(type: type);
});

/// 刷新信号：变更数据后调用 bump() 让相关 Provider 重查。
final planRefreshProvider =
    NotifierProvider<RefreshNotifier, int>(RefreshNotifier.new);
final recordRefreshProvider =
    NotifierProvider<RefreshNotifier, int>(RefreshNotifier.new);

class RefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}
