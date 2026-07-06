import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_settings.dart';
import '../shared/common_widgets.dart';
import 'ai_config_screen.dart';
import 'constraints_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiConfig = ref.watch(aiConfigProvider).valueOrNull ?? const AiConfig();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            _sectionTitle('AI'),
            _tile(
              context,
              icon: Icons.auto_awesome,
              title: 'AI 模型配置',
              subtitle: aiConfig.isConfigured
                  ? '已配置 · 模型 ${aiConfig.model}'
                  : '未配置，AI 功能不可用（支持 DeepSeek / Kimi / 智谱等）',
              trailingWarn: !aiConfig.isConfigured,
              onTap: () => Navigator.of(context)
                  .push(softRoute(const AiConfigScreen())),
            ),
            const SizedBox(height: AppSpacing.md),
            _tile(
              context,
              icon: Icons.tune,
              title: '我的约束条件',
              subtitle: '作息、可支配时段、特殊约束（AI 排计划必读）',
              onTap: () => Navigator.of(context)
                  .push(softRoute(const ConstraintsScreen())),
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionTitle('数据备份'),
            _tile(
              context,
              icon: Icons.upload_file_outlined,
              title: '导出数据',
              subtitle: '把全部数据存成 JSON 文件，防止丢失',
              onTap: () => _export(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
            _tile(
              context,
              icon: Icons.download_outlined,
              title: '导入数据',
              subtitle: '从 JSON 备份文件恢复全部数据（会覆盖现有数据）',
              onTap: () => _import(context, ref),
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionTitle('关于'),
            const SoftCard(
              child: Text(
                '计划 · 记录\n个人专属的「计划 + 记录」双生态 AI 助理。\n数据全部保存在你的手机本地。',
                style: TextStyle(
                    color: AppColors.textSecondary, height: 1.6, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.md),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textStrong)),
      );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool trailingWarn = false,
  }) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.accentWash,
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: AppColors.accent, size: 21),
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
                    style: TextStyle(
                        color: trailingWarn
                            ? AppColors.danger
                            : AppColors.textSecondary,
                        fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(backupServiceProvider).exportToJson();
      final ts = DateTime.now();
      final name =
          'warm_planner_backup_${ts.year}${_pad2(ts.month)}${_pad2(ts.day)}_${_pad2(ts.hour)}${_pad2(ts.minute)}.json';

      // 写入临时文件后用系统分享（可存到文件/发给自己）
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);

      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '计划记录数据备份',
        text: name,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入会用备份文件覆盖当前全部数据，此操作不可撤销。建议先导出当前数据备份。确定继续？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('继续导入')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      const typeGroup = XTypeGroup(
        label: 'JSON 备份',
        extensions: ['json'],
        // 部分安卓机型对扩展名过滤支持有限，放开 mimeType 提升兼容性
        mimeTypes: ['application/json', 'text/plain'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return; // 用户取消
      final content = await file.readAsString();

      final count =
          await ref.read(backupServiceProvider).importFromJson(content);
      // 刷新全 App 数据
      ref.read(planRefreshProvider.notifier).bump();
      ref.read(recordRefreshProvider.notifier).bump();
      ref.invalidate(aiConfigProvider);
      ref.invalidate(constraintsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导入成功，恢复了 $count 条数据 ✓')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0'); // 补零
}
