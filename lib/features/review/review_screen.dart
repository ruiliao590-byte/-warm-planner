import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/goal.dart';
import '../../services/ai/deepseek_service.dart';
import '../settings/settings_screen.dart';
import '../shared/common_widgets.dart';

enum ReviewPeriod { week, month }

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  ReviewPeriod _period = ReviewPeriod.week;
  bool _loading = false;
  String _insight = '';

  // 聚合数据（前端自己算）
  int _total = 0;
  int _completed = 0;
  int _recordCount = 0;
  List<GoalWithProgress> _goals = [];

  @override
  void initState() {
    super.initState();
    _aggregate();
  }

  ({DateTime start, DateTime end}) _range() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = _period == ReviewPeriod.week
        ? end.subtract(const Duration(days: 6))
        : end.subtract(const Duration(days: 29));
    return (start: start, end: end);
  }

  Future<void> _aggregate() async {
    final repo = ref.read(planRepositoryProvider);
    final recordRepo = ref.read(recordRepositoryProvider);
    final r = _range();
    final stats = await repo.completionStats(r.start, r.end);
    final goals = await repo.getGoalsWithProgress();
    final records = await recordRepo.getRecentRecords(r.start, limit: 100);
    if (!mounted) return;
    setState(() {
      _total = stats.total;
      _completed = stats.completed;
      _goals = goals;
      _recordCount = records.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(aiConfiguredProvider);
    final rate = _total == 0 ? 0.0 : _completed / _total;

    return Scaffold(
      appBar: AppBar(title: const Text('复盘洞察')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            // 周期切换
            Row(
              children: [
                _periodChip(ReviewPeriod.week, '本周'),
                const SizedBox(width: AppSpacing.sm),
                _periodChip(ReviewPeriod.month, '本月'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 聚合数字卡
            Row(
              children: [
                Expanded(
                    child: _statCard('任务完成率',
                        '${(rate * 100).round()}%', '$_completed/$_total')),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _statCard(
                        '本周期记录', '$_recordCount', '条复盘/灵感')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('各目标完成情况',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: AppSpacing.md),
                  if (_goals.isEmpty)
                    const Text('还没有目标。',
                        style: TextStyle(color: AppColors.textSecondary))
                  else
                    for (final g in _goals) ...[
                      Row(
                        children: [
                          Expanded(
                              child: Text(g.goal.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                          Text('${g.completedTasks}/${g.totalTasks}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SmoothProgressBar(value: g.progress),
                      const SizedBox(height: AppSpacing.md),
                    ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (!configured)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AiNotConfiguredBanner(
                  onGoSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
              ),

            // AI 洞察
            PressableButton(
              expand: true,
              icon: Icons.insights,
              loading: _loading,
              onPressed: configured ? _generateInsight : null,
              child: Text(_insight.isEmpty ? '生成 AI 洞察' : '重新生成洞察'),
            ),
            if (_insight.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              FadeInUp(
                child: SoftCard(
                  color: AppColors.backgroundAlt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome,
                              color: AppColors.accent, size: 20),
                          SizedBox(width: 8),
                          Text('AI 洞察',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SelectableText(_insight,
                          style: const TextStyle(
                              height: 1.6,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(ReviewPeriod p, String label) {
    final selected = _period == p;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _period = p;
            _insight = '';
          });
          _aggregate();
        },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentWash : AppColors.card,
            borderRadius: AppRadius.button,
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.cardBorder,
                width: selected ? 1.6 : 1),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color:
                        selected ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String big, String sub) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text(big,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  height: 1.1)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12.5)),
        ],
      ),
    );
  }

  Future<void> _generateInsight() async {
    final planner = ref.read(aiPlannerProvider);
    if (planner == null) return;
    setState(() => _loading = true);
    try {
      final recordRepo = ref.read(recordRepositoryProvider);
      final r = _range();
      final records = await recordRepo.getRecentRecords(r.start, limit: 100);
      final insight = await planner.periodInsight(
        periodLabel: _period == ReviewPeriod.week ? '本周' : '本月',
        goals: _goals,
        stats: (total: _total, completed: _completed),
        records: records,
      );
      if (!mounted) return;
      setState(() => _insight = insight);
    } on AiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
