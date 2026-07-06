import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task.dart';
import '../../services/notifications/notification_service.dart';
import '../shared/animated_check.dart';
import '../shared/common_widgets.dart';

/// 晚间复盘：逐条确认今天完成情况（直接勾选打卡）；
/// 对未完成的任务，选择「顺延到明天 / 放弃」。
class EveningReviewScreen extends ConsumerWidget {
  const EveningReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final tasksAsync =
        ref.watch(tasksForDateProvider(DateTime(today.year, today.month, today.day)));

    return Scaffold(
      appBar: AppBar(title: const Text('晚间复盘')),
      body: SafeArea(
        child: tasksAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (tasks) {
            if (tasks.isEmpty) {
              return const EmptyState(
                icon: Icons.nightlight_outlined,
                title: '今天没有任务',
                subtitle: '好好休息，明天见。',
              );
            }
            final done = tasks.where((t) => t.isCompleted).length;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: [
                SoftCard(
                  color: AppColors.accentWash,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('今天完成了 $done / ${tasks.length}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.sm),
                      SmoothProgressBar(
                          value: tasks.isEmpty ? 0 : done / tasks.length),
                      const SizedBox(height: AppSpacing.md),
                      const Text('勾选已完成的；没做的，选择顺延到明天或放弃。',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final t in tasks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ReviewTile(task: t),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  final Task task;
  const _ReviewTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              AnimatedCheck(
                checked: task.isCompleted,
                onChanged: (_) => _toggle(ref),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(task.title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted
                          ? AppColors.textMuted
                          : AppColors.textStrong,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    )),
              ),
            ],
          ),
          if (!task.isCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _carryOver(ref, context),
                    icon: const Icon(Icons.east, size: 18),
                    label: const Text('顺延到明天'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _giveUp(ref, context),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('放弃'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toggle(WidgetRef ref) async {
    final nowCompleted = !task.isCompleted;
    await ref
        .read(planRepositoryProvider)
        .setTaskCompleted(task.id, nowCompleted);
    await NotificationService.syncForTask(
        task.copyWith(isCompleted: nowCompleted));
    ref.read(planRefreshProvider.notifier).bump();
  }

  Future<void> _carryOver(WidgetRef ref, BuildContext context) async {
    final tomorrow = task.date.add(const Duration(days: 1));
    // 提醒时间也顺延一天（如果设置了）
    final movedReminder = task.reminderTime?.add(const Duration(days: 1));
    final moved = task.copyWith(
      date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      reminderTime: movedReminder,
    );
    await ref.read(planRepositoryProvider).upsertTask(moved);
    await NotificationService.syncForTask(moved);
    ref.read(planRefreshProvider.notifier).bump();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已顺延到明天')));
    }
  }

  Future<void> _giveUp(WidgetRef ref, BuildContext context) async {
    await ref.read(planRepositoryProvider).deleteTask(task.id);
    await NotificationService.cancelForTask(task.id);
    ref.read(planRefreshProvider.notifier).bump();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已放弃这个任务')));
    }
  }
}
