import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/record.dart';
import '../shared/common_widgets.dart';
import 'record_edit_screen.dart';

/// 当前筛选类型：null=全部, 'review', 'inspiration'
final _recordFilterProvider = StateProvider<String?>((ref) => null);

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_recordFilterProvider);
    final recordsAsync = ref.watch(recordsProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('记录')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _chooseType(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.sm),
              child: Row(
                children: [
                  _filterChip(ref, null, '全部'),
                  const SizedBox(width: AppSpacing.sm),
                  _filterChip(ref, 'review', '复盘'),
                  const SizedBox(width: AppSpacing.sm),
                  _filterChip(ref, 'inspiration', '灵感'),
                ],
              ),
            ),
            Expanded(
              child: recordsAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent)),
                error: (e, _) => Center(child: Text('加载失败：$e')),
                data: (records) {
                  if (records.isEmpty) {
                    return EmptyState(
                      icon: Icons.edit_note_outlined,
                      title: '还没有记录',
                      subtitle: '记录踩过的坑或闪现的灵感，AI 可以帮你补充建议。',
                      action: PressableButton(
                        icon: Icons.add,
                        onPressed: () => _chooseType(context),
                        child: const Text('写第一条'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4,
                        AppSpacing.page, 100),
                    itemCount: records.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) => FadeInUp(
                      index: i,
                      child: _RecordCard(record: records[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String? value, String label) {
    final selected = ref.watch(_recordFilterProvider) == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          ref.read(_recordFilterProvider.notifier).state = value,
    );
  }

  Future<void> _chooseType(BuildContext context) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('新建记录',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.lg),
              _typeOption(ctx, 'review', Icons.report_gmailerrorred_outlined,
                  AppColors.reviewTag, '复盘型（踩坑）',
                  '情境 → 问题 → 分析 → 下次怎么办'),
              const SizedBox(height: AppSpacing.md),
              _typeOption(ctx, 'inspiration', Icons.lightbulb_outline,
                  AppColors.inspirationTag, '灵感型（好想法）',
                  '想到了什么 → 触发场景'),
            ],
          ),
        ),
      ),
    );
    if (type != null && context.mounted) {
      Navigator.of(context)
          .push(softRoute(RecordEditScreen(type: type)));
    }
  }

  Widget _typeOption(BuildContext ctx, String value, IconData icon,
      Color color, String title, String subtitle) {
    return SoftCard(
      onTap: () => Navigator.pop(ctx, value),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final RecordEntry record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final color =
        record.isReview ? AppColors.reviewTag : AppColors.inspirationTag;
    return SoftCard(
      onTap: () => Navigator.of(context)
          .push(softRoute(RecordEditScreen(existing: record))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TinyTag(text: record.isReview ? '复盘' : '灵感', color: color),
              const Spacer(),
              Text(DateFormat('M月d日').format(record.createdAt),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(record.previewTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                  height: 1.4)),
          if (record.aiSuggestion.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text('已有 AI 建议',
                    style: TextStyle(
                        color: AppColors.accent.withOpacity(0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
