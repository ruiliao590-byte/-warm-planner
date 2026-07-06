import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/goal.dart';
import '../../data/models/task.dart';
import '../../services/ai/ai_planner.dart';
import '../../services/ai/deepseek_service.dart';
import '../settings/settings_screen.dart';
import '../shared/common_widgets.dart';
import 'plan_preview.dart';

/// AI 自动排计划：选范围 → 生成 → 预览确认。
class GeneratePlanScreen extends ConsumerStatefulWidget {
  final String? freeformRequest; // 从“一句话开始”带入
  const GeneratePlanScreen({super.key, this.freeformRequest});

  @override
  ConsumerState<GeneratePlanScreen> createState() =>
      _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends ConsumerState<GeneratePlanScreen> {
  PlanScope _scope = PlanScope.today;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(aiConfiguredProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI 排计划')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            if (!configured)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: AiNotConfiguredBanner(
                  onGoSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
              ),
            Text('为哪个范围排计划？',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final s in PlanScope.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _scopeCard(s),
              ),
            const SizedBox(height: AppSpacing.lg),
            SoftCard(
              color: AppColors.accentWash,
              child: Row(
                children: const [
                  Icon(Icons.spa_outlined, color: AppColors.accent, size: 20),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'AI 会读取你的目标、约束、近期完成情况和记录，并刻意留白——宁可少排，也让你能真正完成。',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PressableButton(
              expand: true,
              icon: Icons.auto_awesome,
              loading: _loading,
              onPressed: configured ? _generate : null,
              child: Text(_loading ? '正在排计划…' : '开始生成'),
            ),
            if (!configured)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Text('需要先在「设置」配置 DeepSeek 才能生成。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scopeCard(PlanScope s) {
    final selected = _scope == s;
    final desc = switch (s) {
      PlanScope.today => '只排今天，聚焦当下',
      PlanScope.week => '排未来 7 天，留出轻松日',
      PlanScope.month => '粗排 30 天节奏',
    };
    return GestureDetector(
      onTap: () => setState(() => _scope = s),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentWash : AppColors.card,
          borderRadius: AppRadius.card,
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.cardBorder,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    final planner = ref.read(aiPlannerProvider);
    if (planner == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(planRepositoryProvider);
      final recordRepo = ref.read(recordRepositoryProvider);
      final constraints =
          await ref.read(constraintsProvider.future);
      final goals = await repo.getGoalsWithProgress(includeCompleted: false);
      final today = DateTime.now();
      final since = today.subtract(const Duration(days: 14));
      final stats = await repo.completionStats(since, today);
      final records = await recordRepo.getRecentRecords(since, limit: 20);

      final planned = await planner.generatePlan(
        scope: _scope,
        goals: goals,
        constraints: constraints,
        today: today,
        recentStats: stats,
        recentRecords: records,
        freeformRequest: widget.freeformRequest,
      );

      if (!mounted) return;
      if (planned.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI 这次没有排出任务，可以再试一次或调整目标。')));
        return;
      }
      final tasks = planned.map((p) => p.toTask()).toList();
      _openPreview(tasks, goals);
    } on AiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPreview(List<Task> tasks, List<GoalWithProgress> goals) {
    final goalNames = {for (final g in goals) g.goal.id: g.goal.name};
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlanPreviewScreen(tasks: tasks, goalNames: goalNames),
    ));
  }
}
