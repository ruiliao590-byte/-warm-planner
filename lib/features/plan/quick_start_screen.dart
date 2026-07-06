import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../shared/common_widgets.dart';
import 'generate_plan_screen.dart';

/// 极简起步：什么都不用先配置，用一句话描述，AI 直接排计划。
class QuickStartScreen extends ConsumerStatefulWidget {
  const QuickStartScreen({super.key});

  @override
  ConsumerState<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends ConsumerState<QuickStartScreen> {
  final _controller = TextEditingController();

  static const _examples = [
    '我想每天运动30分钟 + 学英语1小时',
    '这周想把 React 入门，顺便早睡',
    '每天读书、写日记，周末去跑步',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(aiConfiguredProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('一句话开始')),
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
            Text('不用先建目标，直接说说你想做什么',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('AI 会先帮你把今天的计划排出来，用起来之后再慢慢完善目标和约束。',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: '例如：我想每天运动30分钟 + 学英语1小时'),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final ex in _examples)
                  ActionChip(
                    label: Text(ex,
                        style: const TextStyle(fontSize: 12.5)),
                    onPressed: () => _controller.text = ex,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PressableButton(
              expand: true,
              icon: Icons.auto_awesome,
              onPressed: configured ? _go : null,
              child: const Text('让 AI 排今天的计划'),
            ),
          ],
        ),
      ),
    );
  }

  void _go() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('先写一句你想做的事')));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GeneratePlanScreen(freeformRequest: text),
    ));
  }
}
