import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/goal.dart';
import '../shared/common_widgets.dart';
import 'goal_edit_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsWithProgressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('目标')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).push(softRoute(const GoalEditScreen())),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (goals) {
            if (goals.isEmpty) {
              return EmptyState(
                icon: Icons.flag_outlined,
                title: '还没有目标',
                subtitle: '建立一个目标，完成关联任务时进度会自动增长。',
                action: PressableButton(
                  icon: Icons.add,
                  onPressed: () => Navigator.of(context)
                      .push(softRoute(const GoalEditScreen())),
                  child: const Text('创建第一个目标'),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, AppSpacing.lg, AppSpacing.page, 100),
              itemCount: goals.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => FadeInUp(
                index: i,
                child: _GoalCard(data: goals[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final GoalWithProgress data;
  const _GoalCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = data.goal;
    return SoftCard(
      onTap: () => Navigator.of(context)
          .push(softRoute(GoalEditScreen(goal: goal))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: goal.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textStrong,
                    decoration: goal.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              TinyTag(text: goal.category, color: AppColors.accent),
            ],
          ),
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(goal.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text('${data.progressPercent}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      fontSize: 15)),
              const SizedBox(width: 8),
              Text('已完成 ${data.completedTasks}/${data.totalTasks} 个任务',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              Text(goal.type == 'long' ? '长期' : '短期',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SmoothProgressBar(value: data.progress),
        ],
      ),
    );
  }
}
