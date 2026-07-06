import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/id.dart';
import '../../data/models/record.dart';
import '../../services/ai/deepseek_service.dart';
import '../settings/settings_screen.dart';
import '../shared/common_widgets.dart';

/// 新建（传 type）或编辑（传 existing）记录，双模式表单 + AI 给建议。
class RecordEditScreen extends ConsumerStatefulWidget {
  final String? type;
  final RecordEntry? existing;
  const RecordEditScreen({super.key, this.type, this.existing});

  @override
  ConsumerState<RecordEditScreen> createState() => _RecordEditScreenState();
}

class _RecordEditScreenState extends ConsumerState<RecordEditScreen> {
  late final String _type;
  final _c = <String, TextEditingController>{};
  String _aiSuggestion = '';
  bool _aiLoading = false;

  bool get _isReview => _type == 'review';
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.type ?? 'review';
    _aiSuggestion = e?.aiSuggestion ?? '';
    for (final k in [
      'situation',
      'problem',
      'analysis',
      'nextAction',
      'idea',
      'triggerContext'
    ]) {
      _c[k] = TextEditingController();
    }
    if (e != null) {
      _c['situation']!.text = e.situation;
      _c['problem']!.text = e.problem;
      _c['analysis']!.text = e.analysis;
      _c['nextAction']!.text = e.nextAction;
      _c['idea']!.text = e.idea;
      _c['triggerContext']!.text = e.triggerContext;
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _isReview ? AppColors.reviewTag : AppColors.inspirationTag;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isReview ? '复盘记录' : '灵感记录'),
        actions: [
          if (_isEdit)
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                onPressed: _delete),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            if (_isReview) ...[
              _field('situation', '情境', '当时是什么情况？', color),
              _field('problem', '遇到的问题', '具体卡在哪、出了什么问题？', color),
              _field('analysis', '我的分析', '为什么会这样？根因是什么？', color),
              _field('nextAction', '下次怎么办', '下次我打算这样做…', color),
            ] else ...[
              _field('idea', '我想到了什么', '这个想法是…', color),
              _field('triggerContext', '触发场景 / 背景', '当时在做什么、什么触发的？', color),
            ],
            const SizedBox(height: AppSpacing.md),
            PressableButton(
              expand: true,
              onPressed: _save,
              child: Text(_isEdit ? '保存' : '保存记录'),
            ),
            const SizedBox(height: AppSpacing.xl),
            _aiSection(color),
          ],
        ),
      ),
    );
  }

  Widget _field(String key, String label, String hint, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14.5)),
              ],
            ),
          ),
          TextField(
            controller: _c[key],
            maxLines: null,
            minLines: 2,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  Widget _aiSection(Color color) {
    return SoftCard(
      color: AppColors.backgroundAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text('AI 建议',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              PressableButton(
                filled: false,
                loading: _aiLoading,
                onPressed: _askAi,
                child: Text(_aiSuggestion.isEmpty ? '让 AI 给建议' : '重新生成'),
              ),
            ],
          ),
          if (_aiSuggestion.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SelectableText(_aiSuggestion,
                style: const TextStyle(
                    height: 1.6, color: AppColors.textPrimary, fontSize: 15)),
          ] else if (!_aiLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isReview
                  ? '让 AI 针对这次踩坑补充改进建议。'
                  : '让 AI 为这个灵感给延伸思路和可行性建议。',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13.5),
            ),
          ],
        ],
      ),
    );
  }

  RecordEntry _buildEntry() {
    final now = DateTime.now();
    final base = widget.existing ??
        RecordEntry(
          id: newId(),
          type: _type,
          createdAt: now,
          updatedAt: now,
        );
    return base.copyWith(
      situation: _c['situation']!.text.trim(),
      problem: _c['problem']!.text.trim(),
      analysis: _c['analysis']!.text.trim(),
      nextAction: _c['nextAction']!.text.trim(),
      idea: _c['idea']!.text.trim(),
      triggerContext: _c['triggerContext']!.text.trim(),
      aiSuggestion: _aiSuggestion,
      updatedAt: now,
    );
  }

  bool _hasContent() {
    if (_isReview) {
      return [_c['situation'], _c['problem'], _c['analysis'], _c['nextAction']]
          .any((c) => c!.text.trim().isNotEmpty);
    }
    return [_c['idea'], _c['triggerContext']]
        .any((c) => c!.text.trim().isNotEmpty);
  }

  Future<void> _save() async {
    if (!_hasContent()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('写点内容再保存吧')));
      return;
    }
    await ref.read(recordRepositoryProvider).upsertRecord(_buildEntry());
    ref.read(recordRefreshProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _askAi() async {
    final planner = ref.read(aiPlannerProvider);
    if (planner == null) {
      _promptConfigure();
      return;
    }
    if (!_hasContent()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('先写点内容，AI 才好给建议')));
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final suggestion = await planner.recordSuggestion(_buildEntry());
      if (!mounted) return;
      setState(() => _aiSuggestion = suggestion);
      // 自动保存带上 AI 建议
      await ref.read(recordRepositoryProvider).upsertRecord(_buildEntry());
      ref.read(recordRefreshProvider.notifier).bump();
    } on AiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _promptConfigure() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('还没配置 AI'),
        content: const Text('前往「设置」填写 DeepSeek API Key 后即可使用 AI 建议。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
              child: const Text('去设置')),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条记录？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(recordRepositoryProvider)
        .deleteRecord(widget.existing!.id);
    ref.read(recordRefreshProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }
}
