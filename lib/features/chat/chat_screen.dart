import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai/deepseek_service.dart';
import '../plan/generate_plan_screen.dart';
import '../settings/settings_screen.dart';
import '../shared/common_widgets.dart';
import 'evening_review_screen.dart';

class _ChatBubble {
  final String role; // user / assistant
  final String text;
  _ChatBubble(this.role, this.text);
}

/// 对话式动态调整（核心交互）：晨间确认/生成、晚间复盘、每周回顾。
/// 日常高频的“打卡”不在这里打字——那在今日页直接点勾选。这里用于深度调整。
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatBubble> _messages = [];
  bool _sending = false;
  String _systemContext = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // 组装对话上下文：今天的计划 + 目标 + 约束
    final repo = ref.read(planRepositoryProvider);
    final today = DateTime.now();
    final tasks = await repo.getTasksForDate(today);
    final goals = await repo.getGoalsWithProgress(includeCompleted: false);
    final constraints = await ref.read(constraintsProvider.future);

    final taskText = tasks.isEmpty
        ? '（今天还没有任务）'
        : tasks
            .map((t) =>
                '- ${t.title}${t.isCompleted ? '（已完成）' : '（未完成）'}')
            .join('\n');
    final goalText = goals.isEmpty
        ? '（暂无目标）'
        : goals
            .map((g) => '- ${g.goal.name}（进度${g.progressPercent}%）')
            .join('\n');

    _systemContext = '''
你是用户温暖、务实的私人计划助手。你可以帮他确认/调整今天的安排、做晚间复盘、每周回顾。
原则：简洁、真诚、不啰嗦；鼓励但不灌鸡汤；务实留白，不把日程排满。
如果用户完成率低，主动关心是不是目标太高/时间不够，给可执行的调整建议，而不是机械堆积任务。

【今天的日期】${today.year}-${today.month}-${today.day}
【今天的计划】
$taskText
【进行中的目标】
$goalText
【用户的约束】
${constraints.toPromptText()}''';

    final hour = today.hour;
    final opener = hour < 11
        ? '早上好！要不要一起过一遍今天的安排？'
        : hour >= 18
            ? '晚上好，今天过得怎么样？我们来复盘一下今天吧。'
            : '嗨，我在。今天的安排需要调整吗？';
    setState(() => _messages.add(_ChatBubble('assistant', opener)));
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(aiConfiguredProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('对话调整')),
      body: SafeArea(
        child: Column(
          children: [
            if (!configured)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: AiNotConfiguredBanner(
                  onGoSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(AppSpacing.page),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _messages.length) {
                    return const _TypingBubble();
                  }
                  return _bubble(_messages[i]);
                },
              ),
            ),
            _quickActions(),
            _inputBar(configured),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_ChatBubble m) {
    final isUser = m.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accent : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.cardBorder),
              ),
              child: SelectableText(
                m.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          _actionChip('🌙 晚间复盘', () {
            Navigator.of(context)
                .push(softRoute(const EveningReviewScreen()));
          }),
          const SizedBox(width: AppSpacing.sm),
          _actionChip('🔄 重排今天剩余', _replanToday),
          const SizedBox(width: AppSpacing.sm),
          _actionChip('📅 生成下周计划', () {
            Navigator.of(context).push(softRoute(const GeneratePlanScreen()));
          }),
          const SizedBox(width: AppSpacing.sm),
          _actionChip('💬 完成率低怎么办', () => _quickAsk('我最近完成率有点低，怎么调整比较好？')),
        ],
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
      backgroundColor: AppColors.accentWash,
      side: BorderSide.none,
    );
  }

  Widget _inputBar(bool configured) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              enabled: configured && !_sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: configured ? '说点什么…' : '请先在设置配置 AI',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: (configured && !_sending) ? _send : null,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (configured && !_sending)
                    ? AppColors.accent
                    : AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _quickAsk(String text) {
    _input.text = text;
    _send();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final service = ref.read(deepSeekServiceProvider);
    if (service == null) return;

    setState(() {
      _messages.add(_ChatBubble('user', text));
      _input.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final history = <AiMessage>[
        AiMessage('system', _systemContext),
        ..._messages.map((m) => AiMessage(m.role, m.text)),
      ];
      final reply = await service.chat(history);
      if (!mounted) return;
      setState(() => _messages.add(_ChatBubble('assistant', reply)));
    } on AiException catch (e) {
      if (mounted) {
        setState(() =>
            _messages.add(_ChatBubble('assistant', '（出错了）${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _replanToday() async {
    final planner = ref.read(aiPlannerProvider);
    if (planner == null) return;
    // 直接进入排计划（今日）流程
    Navigator.of(context).push(softRoute(const GeneratePlanScreen()));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: AppDurations.normal, curve: AppDurations.curve);
      }
    });
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const SizedBox(
        width: 40,
        child: Text('正在输入…',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ),
    );
  }
}
