import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/id.dart';
import '../../data/models/goal.dart';
import '../../data/models/task.dart';
import '../../services/notifications/notification_service.dart';
import '../chat/chat_screen.dart';
import 'task_detail_sheet.dart';
import '../plan/generate_plan_screen.dart';
import '../plan/quick_start_screen.dart';
import '../shared/animated_check.dart';
import '../shared/common_widgets.dart';

/// 晨间问候 Provider：优先用 AI，一句结合今天计划的问候；未配置/失败则本地兜底。
///
/// 注意：只依赖 selectedDate（按天计算一次），不监听任务完成变化——
/// 否则每次打卡都会触发一次 AI 请求，浪费额度。下拉刷新可手动重取。
final _greetingProvider = FutureProvider.autoDispose<String>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final tasks =
      await ref.read(planRepositoryProvider).getTasksForDate(date);
  final planner = ref.watch(aiPlannerProvider);
  final hour = DateTime.now().hour;
  final part = hour < 11
      ? '早上好'
      : hour < 14
          ? '中午好'
          : hour < 18
              ? '下午好'
              : '晚上好';
  final done = tasks.where((t) => t.isCompleted).length;

  String fallback() {
    if (tasks.isEmpty) return '$part。今天还没有安排，先从一件小事开始吧。';
    if (done == tasks.length) return '$part。今天 ${tasks.length} 件事都完成了，为你高兴 🎉';
    return '$part。今天有 ${tasks.length} 件事，已完成 $done 件，慢慢来。';
  }

  if (planner == null) return fallback();
  try {
    return await planner.morningGreeting(
        todayTasks: tasks, today: DateTime.now());
  } catch (_) {
    return fallback();
  }
});

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(todayTasksProvider);
    final isToday = _isSameDay(date, DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.read(planRefreshProvider.notifier).bump();
            ref.invalidate(_greetingProvider);
            await ref.read(todayTasksProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.page, AppSpacing.lg, AppSpacing.page, 120),
            children: [
              _Header(date: date, isToday: isToday),
              const SizedBox(height: AppSpacing.lg),
              const _GreetingCard(),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text('今天要做的事',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  tasksAsync.maybeWhen(
                    data: (tasks) => tasks.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            '${tasks.where((t) => t.isCompleted).length}/${tasks.length}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              tasksAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent)),
                ),
                error: (e, _) => Text('加载失败：$e'),
                data: (tasks) => _TaskList(tasks: tasks, date: date),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).push(softRoute(const ChatScreen())),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.forum_outlined),
        label: const Text('对话调整',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  const _Header({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('M月d日 EEEE', 'zh_CN');
    String dateText;
    try {
      dateText = df.format(date);
    } catch (_) {
      dateText = DateFormat('M月d日').format(date);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isToday ? '今日' : '计划',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 2),
            Text(dateText,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _GreetingCard extends ConsumerWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(_greetingProvider);
    return FadeInUp(
      child: SoftCard(
        color: AppColors.accentWash,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: greeting.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('正在为你准备今天的问候…',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                error: (_, __) => const Text('早上好，愿今天顺利。',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5)),
                data: (msg) => AnimatedSwitcher(
                  duration: AppDurations.normal,
                  child: Text(msg,
                      key: ValueKey(msg),
                      style: const TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 15.5,
                          height: 1.55,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  final List<Task> tasks;
  final DateTime date;
  const _TaskList({required this.tasks, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.spa_outlined,
                  size: 44, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              const Text('今天还没有计划',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('让 AI 帮你排一份，或用一句话快速开始。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: PressableButton(
                      icon: Icons.auto_awesome,
                      expand: true,
                      onPressed: () => Navigator.of(context).push(
                          softRoute(const GeneratePlanScreen())),
                      child: const Text('AI 排计划'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PressableButton(
                      icon: Icons.bolt_outlined,
                      filled: false,
                      expand: true,
                      onPressed: () => Navigator.of(context)
                          .push(softRoute(const QuickStartScreen())),
                      child: const Text('一句话开始'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 目标名映射，用于任务展示所属目标
    final goalsAsync = ref.watch(goalsWithProgressProvider);
    final goalNames = <String, String>{
      for (final g in goalsAsync.valueOrNull ?? const <GoalWithProgress>[])
        g.goal.id: g.goal.name,
    };

    return Column(
      children: [
        for (int i = 0; i < tasks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FadeInUp(
              index: i,
              child: _TaskTile(
                task: tasks[i],
                goalName: tasks[i].goalId == null
                    ? null
                    : goalNames[tasks[i].goalId],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        PressableButton(
          icon: Icons.add,
          filled: false,
          expand: true,
          onPressed: () => _addQuickTask(context, ref),
          child: const Text('加一个任务'),
        ),
      ],
    );
  }

  Future<void> _addQuickTask(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('加一个任务'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：晚上护肤'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('添加')),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty) return;
    final repo = ref.read(planRepositoryProvider);
    await repo.upsertTask(Task(
      id: newId(),
      title: title.trim(),
      date: date,
      createdAt: DateTime.now(),
      orderIndex: tasks.length,
    ));
    ref.read(planRefreshProvider.notifier).bump();
  }
}

/// 单个任务行：可直接点勾选框打卡，带丝滑动画 + 完成后柔和划掉/渐隐。
class _TaskTile extends ConsumerWidget {
  final Task task;
  final String? goalName;
  const _TaskTile({required this.task, this.goalName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      onTap: () => _toggle(ref),
      child: Row(
        children: [
          AnimatedCheck(
            checked: task.isCompleted,
            onChanged: (_) => _toggle(ref),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: AppDurations.normal,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: task.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textStrong,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.textMuted,
                  ),
                  child: Text(task.title),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (goalName != null)
                      _MetaChip(
                          icon: Icons.flag_outlined, text: goalName!),
                    if (task.suggestedSlot.isNotEmpty)
                      _MetaChip(
                          icon: Icons.schedule, text: task.suggestedSlot),
                    _MetaChip(
                        icon: Icons.timelapse,
                        text: '${task.estimatedMinutes}分钟'),
                    if (task.reminderTime != null)
                      _MetaChip(
                        icon: Icons.notifications_active_outlined,
                        text: DateFormat('HH:mm').format(task.reminderTime!),
                        color: AppColors.accent,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
            onPressed: () => showTaskDetailSheet(context, ref, task),
          ),
        ],
      ),
    );
  }

  void _toggle(WidgetRef ref) async {
    final nowCompleted = !task.isCompleted;
    await ref
        .read(planRepositoryProvider)
        .setTaskCompleted(task.id, nowCompleted);
    // 完成后取消提醒；取消完成则按需恢复提醒
    await NotificationService.syncForTask(
        task.copyWith(isCompleted: nowCompleted));
    // 目标进度条随之自动推进（goalsWithProgress 依赖 planRefresh）
    ref.read(planRefreshProvider.notifier).bump();
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MetaChip({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? AppColors.textMuted),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 12.5,
                color: color ?? AppColors.textSecondary,
                fontWeight:
                    color != null ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
