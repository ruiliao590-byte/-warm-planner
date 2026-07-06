import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task.dart';
import '../shared/common_widgets.dart';

/// AI 排好的计划预览：可逐条删除，确认后落库。
class PlanPreviewScreen extends ConsumerStatefulWidget {
  final List<Task> tasks;
  final Map<String, String> goalNames;
  const PlanPreviewScreen(
      {super.key, required this.tasks, required this.goalNames});

  @override
  ConsumerState<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends ConsumerState<PlanPreviewScreen> {
  late final List<Task> _tasks = List.of(widget.tasks);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    // 按日期分组
    final byDate = <int, List<Task>>{};
    for (final t in _tasks) {
      byDate.putIfAbsent(Task.dayKeyOf(t.date), () => []).add(t);
    }
    final dateKeys = byDate.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('确认计划')),
      body: SafeArea(
        child: _tasks.isEmpty
            ? const EmptyState(
                icon: Icons.inbox_outlined,
                title: '没有任务了',
                subtitle: '返回重新生成，或手动添加。')
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page, AppSpacing.md, AppSpacing.page, 120),
                children: [
                  SoftCard(
                    color: AppColors.accentWash,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.accent),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text('AI 共排了 ${_tasks.length} 个任务，滑动可删除不想要的，确认后加入计划。',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final key in dateKeys) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 4, bottom: 8, top: 4),
                      child: Text(
                        _dateLabel(
                            DateTime.fromMillisecondsSinceEpoch(key)),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                            fontSize: 15),
                      ),
                    ),
                    for (final t in byDate[key]!)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                                color: AppColors.danger
                                    .withOpacity(0.12),
                                borderRadius: AppRadius.card),
                            child: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                          ),
                          onDismissed: (_) =>
                              setState(() => _tasks.remove(t)),
                          child: _previewTile(t),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: _tasks.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: PressableButton(
                  expand: true,
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: _confirm,
                  child: Text('确认，加入我的计划（${_tasks.length}）'),
                ),
              ),
            ),
    );
  }

  Widget _previewTile(Task t) {
    final goalName = t.goalId == null ? null : widget.goalNames[t.goalId];
    return SoftCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  children: [
                    if (goalName != null)
                      _meta(Icons.flag_outlined, goalName),
                    if (t.suggestedSlot.isNotEmpty)
                      _meta(Icons.schedule, t.suggestedSlot),
                    _meta(Icons.timelapse, '${t.estimatedMinutes}分钟'),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.swipe_left_alt,
              size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text(text,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      );

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    final base = DateFormat('M月d日 E', 'zh_CN');
    String prefix = '';
    if (diff == 0) prefix = '今天 · ';
    if (diff == 1) prefix = '明天 · ';
    try {
      return '$prefix${base.format(d)}';
    } catch (_) {
      return '$prefix${DateFormat('M月d日').format(d)}';
    }
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      // 重排 orderIndex
      final tasks = <Task>[];
      for (int i = 0; i < _tasks.length; i++) {
        tasks.add(_tasks[i].copyWith(orderIndex: i));
      }
      await ref.read(planRepositoryProvider).upsertTasks(tasks);
      ref.read(planRefreshProvider.notifier).bump();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('计划已加入 ✓')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
