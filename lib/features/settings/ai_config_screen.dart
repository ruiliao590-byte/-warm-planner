import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_settings.dart';
import '../../services/ai/deepseek_service.dart';
import '../shared/common_widgets.dart';

/// AI 服务商预设：只要是 OpenAI 兼容的 chat/completions 接口都能用。
/// 选一个即可自动填好 API 地址与常用模型名；你也可以随后手动改。
class AiProviderPreset {
  final String name;
  final String baseUrl;
  final String model;
  final String keyHint; // 去哪拿 Key 的提示
  const AiProviderPreset(this.name, this.baseUrl, this.model, this.keyHint);
}

const List<AiProviderPreset> kAiProviders = [
  AiProviderPreset('DeepSeek 深度求索',
      'https://api.deepseek.com/v1/chat/completions', 'deepseek-chat',
      'platform.deepseek.com'),
  AiProviderPreset('Kimi 月之暗面',
      'https://api.moonshot.cn/v1/chat/completions', 'moonshot-v1-8k',
      'platform.moonshot.cn'),
  AiProviderPreset('智谱 GLM',
      'https://open.bigmodel.cn/api/paas/v4/chat/completions', 'glm-4-flash',
      'bigmodel.cn'),
  AiProviderPreset('通义千问 Qwen',
      'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      'qwen-plus', 'dashscope.console.aliyun.com'),
  AiProviderPreset('硅基流动 SiliconFlow',
      'https://api.siliconflow.cn/v1/chat/completions',
      'deepseek-ai/DeepSeek-V3', 'siliconflow.cn'),
  AiProviderPreset('OpenAI',
      'https://api.openai.com/v1/chat/completions', 'gpt-4o-mini',
      'platform.openai.com'),
  AiProviderPreset('OpenRouter',
      'https://openrouter.ai/api/v1/chat/completions',
      'deepseek/deepseek-chat', 'openrouter.ai'),
];

/// AI 配置：选服务商 + 填 API Key / API 地址 / 模型名。Key 只存本地。
class AiConfigScreen extends ConsumerStatefulWidget {
  const AiConfigScreen({super.key});

  @override
  ConsumerState<AiConfigScreen> createState() => _AiConfigScreenState();
}

class _AiConfigScreenState extends ConsumerState<AiConfigScreen> {
  final _key = TextEditingController();
  final _url = TextEditingController();
  final _model = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  bool _loaded = false;

  @override
  void dispose() {
    _key.dispose();
    _url.dispose();
    _model.dispose();
    super.dispose();
  }

  void _fill(AiConfig c) {
    if (_loaded) return;
    _key.text = c.apiKey;
    _url.text = c.baseUrl;
    _model.text = c.model;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(aiConfigProvider);
    async.whenData(_fill);

    return Scaffold(
      appBar: AppBar(title: const Text('AI 模型配置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            const SoftCard(
              color: AppColors.accentWash,
              child: Text(
                '支持任意 OpenAI 兼容接口（DeepSeek / Kimi / 智谱 / 通义千问 / OpenAI 等）。'
                '选一个服务商自动填好地址，再填你自己的 Key 即可。Key 仅保存在本机，不上传。',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 13.5, height: 1.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('选择服务商'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in kAiProviders)
                  ChoiceChip(
                    label: Text(p.name),
                    selected: _url.text.trim() == p.baseUrl,
                    onSelected: (_) => _applyPreset(p),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('API Key'),
            TextField(
              controller: _key,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'sk-...',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('API 地址'),
            TextField(
              controller: _url,
              decoration: const InputDecoration(
                  hintText: 'https://api.deepseek.com/v1/chat/completions'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('模型名'),
            TextField(
              controller: _model,
              decoration: const InputDecoration(hintText: 'deepseek-chat'),
            ),
            const SizedBox(height: AppSpacing.xl),
            PressableButton(
              expand: true,
              onPressed: _save,
              child: const Text('保存'),
            ),
            const SizedBox(height: AppSpacing.md),
            PressableButton(
              expand: true,
              filled: false,
              loading: _testing,
              icon: Icons.wifi_tethering,
              onPressed: _test,
              child: const Text('测试连接'),
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

  /// 选择服务商预设：自动填地址与常用模型（Key 保持不动），并提示去哪拿 Key。
  void _applyPreset(AiProviderPreset p) {
    setState(() {
      _url.text = p.baseUrl;
      _model.text = p.model;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到 ${p.name}，去 ${p.keyHint} 获取 API Key')),
    );
  }

  AiConfig _current() => AiConfig(
        apiKey: _key.text.trim(),
        baseUrl: _url.text.trim().isEmpty
            ? 'https://api.deepseek.com/v1/chat/completions'
            : _url.text.trim(),
        model: _model.text.trim().isEmpty ? 'deepseek-chat' : _model.text.trim(),
      );

  Future<void> _save() async {
    await ref.read(aiConfigProvider.notifier).save(_current());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已保存 ✓')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _test() async {
    final config = _current();
    if (!config.isConfigured) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写 API Key')));
      return;
    }
    setState(() => _testing = true);
    try {
      final service = DeepSeekService(config);
      final reply = await service.chat(
        [const AiMessage('user', '请只回复两个字：你好')],
        temperature: 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('连接成功 ✓ AI 回复：$reply')));
      }
    } on AiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('连接失败：${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }
}
