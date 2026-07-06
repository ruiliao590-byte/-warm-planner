import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task.dart';
import '../../services/notifications/notification_service.dart';
import '../shared/common_widgets.dart';

/// 打开任务详情面板：改标题、设定时提醒、删除。
Future<void> showTaskDetailSheet(
    BuildContext context, WidgetRef ref, Task task) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => Padding(
      // 顶起键盘
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _TaskDetailSheet(task: task),
    ),
  );
}

class _TaskDetailSheet extends ConsumerStatefulWidget {
  final Task task;
  const _TaskDetailSheet({required this.task});

  @override
  ConsumerState<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<_TaskDetailSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task.title);
  late DateTime? _reminder = widget.task.reminderTime;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.lg, AppSpacing.page, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('任务',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(hintText: '任务名称'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 提醒设置
            SoftCard(
              color: AppColors.backgroundAlt,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          color: AppColors.accent, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('定时提醒',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15.5)),
                      const Spacer(),
                      Switch(
                        activeColor: AppColors.accent,
                        value: _reminder != null,
                        onChanged: (on) async {
                          if (on) {
                            await _pickReminder();
                          } else {
                            setState(() => _reminder = null);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_reminder != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      borderRadius: AppRadius.button,
                      onTap: _pickReminder,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.button,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('M月d日 HH:mm').format(_reminder!),
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textStrong,
                                  fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            const Text('点击修改',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PressableButton(
              expand: true,
              loading: _saving,
              onPressed: _save,
              child: const Text('保存'),
            ),
            const SizedBox(height: AppSpacing.sm),
            PressableButton(
              expand: true,
              filled: false,
              icon: Icons.delete_outline,
              onPressed: _delete,
              child: const Text('删除任务'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminder() async {
    final base = _reminder ?? widget.task.date;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _reminder =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('任务名称不能为空')));
      return;
    }
    setState(() => _saving = true);
    try {
      // 若设置了提醒，请求一次通知权限
      if (_reminder != null) {
        await NotificationService.requestPermission();
      }
      final finalTask = widget.task.copyWith(
        title: _title.text.trim(),
        reminderTime: _reminder,
        clearReminder: _reminder == null,
      );
      await ref.read(planRepositoryProvider).upsertTask(finalTask);
      await NotificationService.syncForTask(finalTask);
      ref.read(planRefreshProvider.notifier).bump();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    await ref.read(planRepositoryProvider).deleteTask(widget.task.id);
    await NotificationService.cancelForTask(widget.task.id);
    ref.read(planRefreshProvider.notifier).bump();
    if (mounted) Navigator.of(context).pop();
  }
}
