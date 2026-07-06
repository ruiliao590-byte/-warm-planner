import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_settings.dart';
import '../shared/common_widgets.dart';

/// 我的约束条件：作息、可支配时段、特殊约束。AI 排计划必读。
class ConstraintsScreen extends ConsumerStatefulWidget {
  const ConstraintsScreen({super.key});

  @override
  ConsumerState<ConstraintsScreen> createState() => _ConstraintsScreenState();
}

class _ConstraintsScreenState extends ConsumerState<ConstraintsScreen> {
  final _wake = TextEditingController();
  final _sleep = TextEditingController();
  final _workStart = TextEditingController();
  final _workEnd = TextEditingController();
  final _commute = TextEditingController();
  final _freeSlots = TextEditingController();
  final _freeMinutes = TextEditingController();
  final _extra = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in [
      _wake,
      _sleep,
      _workStart,
      _workEnd,
      _commute,
      _freeSlots,
      _freeMinutes,
      _extra
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(UserConstraints c) {
    if (_loaded) return;
    _wake.text = c.wakeTime;
    _sleep.text = c.sleepTime;
    _workStart.text = c.workStart;
    _workEnd.text = c.workEnd;
    _commute.text = c.commuteMinutes.toString();
    _freeSlots.text = c.freeSlots;
    _freeMinutes.text = c.freeMinutesPerDay.toString();
    _extra.text = c.extraConstraints;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(constraintsProvider).whenData(_fill);

    return Scaffold(
      appBar: AppBar(title: const Text('我的约束条件')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            const SoftCard(
              color: AppColors.accentWash,
              child: Text('这些是 AI 排计划时的硬性条件。填得越贴近真实，排出的计划越好执行。',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.5)),
            ),
            const SizedBox(height: AppSpacing.lg),
            _row([
              _timeField('起床', _wake),
              _timeField('睡觉', _sleep),
            ]),
            _row([
              _timeField('上班', _workStart),
              _timeField('下班', _workEnd),
            ]),
            _field('单程通勤（分钟）', _commute,
                keyboard: TextInputType.number, hint: '例如 30'),
            _field('每天可自由支配的时段', _freeSlots,
                hint: '例如：晚上 19:30–22:30；午休 30 分钟'),
            _field('每天可自由支配总时长（分钟）', _freeMinutes,
                keyboard: TextInputType.number, hint: '例如 120'),
            _field('特殊约束（可选）', _extra,
                maxLines: 4,
                hint: '例如：健身房 6:00–22:00 开放；周末只安排轻松任务；周三固定加班'),
            const SizedBox(height: AppSpacing.md),
            PressableButton(
              expand: true,
              onPressed: _save,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: children[i]),
            ]
          ],
        ),
      );

  Widget _timeField(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWidget(label),
        TextField(
          controller: c,
          readOnly: true,
          onTap: () => _pickTime(c),
          decoration: const InputDecoration(
            hintText: '00:00',
            suffixIcon: Icon(Icons.access_time, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboard, int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWidget(label),
          TextField(
            controller: c,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  Widget _labelWidget(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14)),
      );

  Future<void> _pickTime(TextEditingController c) async {
    final parts = c.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      c.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    final c = UserConstraints(
      wakeTime: _wake.text.trim(),
      sleepTime: _sleep.text.trim(),
      workStart: _workStart.text.trim(),
      workEnd: _workEnd.text.trim(),
      commuteMinutes: int.tryParse(_commute.text.trim()) ?? 30,
      freeSlots: _freeSlots.text.trim(),
      freeMinutesPerDay: int.tryParse(_freeMinutes.text.trim()) ?? 120,
      extraConstraints: _extra.text.trim(),
    );
    await ref.read(constraintsProvider.notifier).save(c);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已保存 ✓')));
      Navigator.of(context).pop();
    }
  }
}
