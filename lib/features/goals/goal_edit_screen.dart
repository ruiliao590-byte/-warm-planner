import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/id.dart';
import '../../data/models/goal.dart';
import '../shared/common_widgets.dart';

/// 创建 / 编辑目标。goal 为空即新建。
class GoalEditScreen extends ConsumerStatefulWidget {
  final Goal? goal;
  const GoalEditScreen({super.key, this.goal});

  @override
  ConsumerState<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends ConsumerState<GoalEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late String _category;
  late String _type;
  DateTime? _deadline;
  late bool _completed;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _name = TextEditingController(text: g?.name ?? '');
    _desc = TextEditingController(text: g?.description ?? '');
    _category = g?.category ?? Goal.categories.first;
    _type = g?.type ?? 'short';
    _deadline = g?.deadline;
    _completed = g?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑目标' : '新建目标'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _label('目标名称'),
            TextField(
              controller: _name,
              decoration: const InputDecoration(hintText: '例如：坚持健身'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('分类'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final c in Goal.categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('类型'),
            Row(
              children: [
                _typeChip('short', '短期'),
                const SizedBox(width: AppSpacing.sm),
                _typeChip('long', '长期'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('目标描述'),
            TextField(
              controller: _desc,
              maxLines: 4,
              decoration:
                  const InputDecoration(hintText: '想达成什么？为什么重要？（可选）'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('截止时间（可选）'),
            SoftCard(
              onTap: _pickDeadline,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined,
                      color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _deadline == null
                        ? '未设置'
                        : '${_deadline!.year}-${_deadline!.month}-${_deadline!.day}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  if (_deadline != null)
                    TextButton(
                        onPressed: () => setState(() => _deadline = null),
                        child: const Text('清除')),
                ],
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
                title: const Text('标记为已完成'),
                value: _completed,
                onChanged: (v) => setState(() => _completed = v),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PressableButton(
              expand: true,
              onPressed: _save,
              child: Text(_isEdit ? '保存' : '创建目标'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14)),
      );

  Widget _typeChip(String value, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _type = value),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _type == value
                  ? AppColors.accentWash
                  : AppColors.card,
              borderRadius: AppRadius.button,
              border: Border.all(
                color: _type == value
                    ? AppColors.accent
                    : AppColors.cardBorder,
                width: _type == value ? 1.6 : 1,
              ),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: _type == value
                          ? AppColors.accent
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      );

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写目标名称')));
      return;
    }
    final repo = ref.read(planRepositoryProvider);
    final goal = (widget.goal ??
            Goal(
              id: newId(),
              name: '',
              category: _category,
              createdAt: DateTime.now(),
            ))
        .copyWith(
      name: _name.text.trim(),
      category: _category,
      type: _type,
      description: _desc.text.trim(),
      deadline: _deadline,
      clearDeadline: _deadline == null,
      isCompleted: _completed,
    );
    await repo.upsertGoal(goal);
    ref.read(planRefreshProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除目标'),
        content: const Text('删除后，关联的任务会保留但不再计入此目标进度。确定删除？'),
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
    await ref.read(planRepositoryProvider).deleteGoal(widget.goal!.id);
    ref.read(planRefreshProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }
}
