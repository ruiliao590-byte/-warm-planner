import 'package:uuid/uuid.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/goal.dart';
import '../../data/models/record.dart';
import '../../data/models/task.dart';
import 'deepseek_service.dart';

const _uuid = Uuid();

/// 排计划的范围
enum PlanScope { today, week, month }

extension PlanScopeLabel on PlanScope {
  String get label => switch (this) {
        PlanScope.today => '今日',
        PlanScope.week => '本周',
        PlanScope.month => '本月',
      };
  int get days => switch (this) {
        PlanScope.today => 1,
        PlanScope.week => 7,
        PlanScope.month => 30,
      };
}

/// AI 排出的单个任务（解析自 JSON，尚未落库）
class PlannedTask {
  final String title;
  final String? goalId; // 关联到已有目标（AI 从提供的目标列表里选）
  final DateTime date;
  final String suggestedSlot;
  final int estimatedMinutes;

  PlannedTask({
    required this.title,
    this.goalId,
    required this.date,
    this.suggestedSlot = '',
    this.estimatedMinutes = 30,
  });

  Task toTask() => Task(
        id: _uuid.v4(),
        goalId: goalId,
        title: title,
        date: date,
        suggestedSlot: suggestedSlot,
        estimatedMinutes: estimatedMinutes,
        createdAt: DateTime.now(),
      );
}

/// ============================================================
/// AI 排计划 / 晨间问候 / 复盘洞察的 Prompt 编排（两个生态的“打通”在此发生）
/// ============================================================
class AiPlanner {
  final DeepSeekService ai;
  AiPlanner(this.ai);

  /// 【防排满的硬性系统约束】所有排期共用
  static const String _plannerSystem = '''
你是一个务实、克制、懂得留白的个人计划助手。铁律：
1. 必须现实、必须留白。宁可少排也不要排满。首要目标是「用户能实际完成」，而不是「填满每一天」。
2. 不要把用户所有目标硬塞进每一天。排出人能轻松执行的量。
3. 任务是清单式的「今天要做这几件事」，建议时段仅供参考，不要绑死具体几点几分。
4. 严格遵守用户的作息与约束条件，不要占用睡眠、工作、通勤时间。
5. 参考用户近期的完成率与复盘记录：完成率低时应减量、给更容易执行的任务。
只返回 JSON，不要任何多余文字、解释或 markdown。''';

  /// 生成计划。返回解析好的 PlannedTask 列表。
  Future<List<PlannedTask>> generatePlan({
    required PlanScope scope,
    required List<GoalWithProgress> goals,
    required UserConstraints constraints,
    required DateTime today,
    required ({int total, int completed}) recentStats,
    required List<RecordEntry> recentRecords,
    String? freeformRequest, // 极简起步：一句话描述
  }) async {
    final goalLines = goals.isEmpty
        ? '（用户暂无已建目标）'
        : goals
            .map((g) =>
                '- id=${g.goal.id}｜${g.goal.name}｜分类:${g.goal.category}｜类型:${g.goal.type == 'long' ? '长期' : '短期'}｜当前进度:${g.progressPercent}%｜描述:${g.goal.description}')
            .join('\n');

    final recordLines = recentRecords.isEmpty
        ? '（近期无记录）'
        : recentRecords.take(12).map((r) => '- ${r.toPlainText()}').join('\n');

    final rate = recentStats.total == 0
        ? '暂无历史数据'
        : '${(recentStats.completed / recentStats.total * 100).round()}%（近期完成 ${recentStats.completed}/${recentStats.total}）';

    final dateFmt =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final scopeInstruction = switch (scope) {
      PlanScope.today => '只为「今天（$dateFmt）」排计划，date 全部为今天。',
      PlanScope.week =>
        '为从今天（$dateFmt）起的 7 天排计划，日期不要早于今天；不必每天都排满，可以有轻松日或留白日。',
      PlanScope.month =>
        '为从今天（$dateFmt）起的 30 天排一个粗粒度计划，不必每天都有任务，重点是节奏与留白。',
    };

    final userPrompt = '''
当前日期：$dateFmt
排计划范围：${scope.label}。$scopeInstruction

【我的约束条件（硬性，必须遵守）】
${constraints.toPromptText()}

【我的目标列表】
$goalLines

【我近期的完成情况】
$rate

【我近期的复盘/灵感记录（排计划时请参考，例如我反复卡在的问题）】
$recordLines
${freeformRequest != null && freeformRequest.trim().isNotEmpty ? '\n【我的额外要求 / 一句话描述】\n$freeformRequest\n' : ''}
请据此排出务实、留白、我能真正完成的计划。

只返回如下 JSON 结构（不要多余文字）：
{
  "tasks": [
    {
      "title": "任务名称",
      "goalId": "关联的目标 id（必须来自上面的目标列表；若是额外任务或无目标则填 null）",
      "date": "YYYY-MM-DD",
      "suggestedSlot": "建议时段，如 晚上/通勤路上（可空字符串）",
      "estimatedMinutes": 30
    }
  ]
}''';

    final json = await ai.chatJson([
      AiMessage('system', _plannerSystem),
      AiMessage('user', userPrompt),
    ]);

    final validGoalIds = goals.map((g) => g.goal.id).toSet();
    final list = _asTaskList(json);
    final result = <PlannedTask>[];
    for (final item in list) {
      if (item is! Map) continue;
      final title = (item['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      final rawGoalId = item['goalId']?.toString();
      final goalId = (rawGoalId != null && validGoalIds.contains(rawGoalId))
          ? rawGoalId
          : null;
      result.add(PlannedTask(
        title: title,
        goalId: goalId,
        date: _parseDate(item['date'], today),
        suggestedSlot: (item['suggestedSlot'] ?? '').toString(),
        estimatedMinutes: _parseMinutes(item['estimatedMinutes']),
      ));
    }
    return result;
  }

  /// 晨间问候：结合今天计划的一句简短问候/提醒。
  Future<String> morningGreeting({
    required List<Task> todayTasks,
    required DateTime today,
  }) async {
    final done = todayTasks.where((t) => t.isCompleted).length;
    final taskText = todayTasks.isEmpty
        ? '今天还没有安排任务。'
        : '今天共有 ${todayTasks.length} 件事（已完成 $done 件）：${todayTasks.map((t) => t.title).join('、')}';
    return ai.chat([
      const AiMessage('system',
          '你是温暖、简洁的个人助手。用一句话（不超过40字）给出今天的晨间问候或提醒，语气自然亲切，可点出今天的重点，不要太长、不要客套堆砌。只输出这一句话。'),
      AiMessage('user', taskText),
    ], temperature: 0.8);
  }

  /// 复盘洞察：把聚合数据 + 本周期记录发给 AI，分析反复卡壳点并给调整建议。
  Future<String> periodInsight({
    required String periodLabel,
    required List<GoalWithProgress> goals,
    required ({int total, int completed}) stats,
    required List<RecordEntry> records,
  }) async {
    final goalLines = goals
        .map((g) =>
            '- ${g.goal.name}：完成 ${g.completedTasks}/${g.totalTasks}（${g.progressPercent}%）')
        .join('\n');
    final recordLines = records.isEmpty
        ? '（本周期无记录）'
        : records.map((r) => '- ${r.toPlainText()}').join('\n');
    final rate = stats.total == 0
        ? '无任务数据'
        : '${(stats.completed / stats.total * 100).round()}%（${stats.completed}/${stats.total}）';

    return ai.chat([
      const AiMessage('system',
          '你是善于洞察的个人成长教练。基于用户的数据与记录，指出：哪些计划反复没完成、是否反复卡在同类问题上，并给出温暖而具体的调整建议（是否目标定太高、时间不够、该换方法）。语气克制、真诚、可执行，用条理清晰的中文，不要空话套话。'),
      AiMessage('user', '''
复盘周期：$periodLabel
总体任务完成率：$rate

各目标完成情况：
$goalLines

本周期的复盘/灵感记录：
$recordLines

请给我这个周期的洞察与下一步调整建议。'''),
    ], temperature: 0.7);
  }

  /// 给单条记录的 AI 建议。
  Future<String> recordSuggestion(RecordEntry r) async {
    if (r.isReview) {
      return ai.chat([
        const AiMessage('system',
            '你是务实的复盘教练。针对用户的踩坑复盘，补充具体、可操作的改进建议，帮他下次做得更好。简洁、真诚、有条理。'),
        AiMessage('user',
            '这是我的一条复盘记录：\n情境：${r.situation}\n遇到的问题：${r.problem}\n我的分析：${r.analysis}\n我打算下次这样做：${r.nextAction}\n\n请给我补充改进建议。'),
      ]);
    }
    return ai.chat([
      const AiMessage('system',
          '你是启发性的创意伙伴。针对用户的灵感，给出延伸思路与可行性建议，帮他把想法向前推进一步。简洁、有启发、可落地。'),
      AiMessage('user',
          '这是我的一条灵感记录：\n想法：${r.idea}\n触发背景：${r.triggerContext}\n\n请给我延伸思路和可行性建议。'),
    ]);
  }

  // ---------------- 解析辅助 ----------------
  static List<dynamic> _asTaskList(dynamic json) {
    if (json is List) return json;
    if (json is Map) {
      if (json['tasks'] is List) return json['tasks'] as List;
      if (json['plan'] is List) return json['plan'] as List;
      // 有些模型会返回 {日期: [任务...]} 的形式，尽量展平
      final flat = <dynamic>[];
      for (final v in json.values) {
        if (v is List) flat.addAll(v);
      }
      if (flat.isNotEmpty) return flat;
    }
    return const [];
  }

  static DateTime _parseDate(dynamic raw, DateTime fallback) {
    if (raw is String) {
      final d = DateTime.tryParse(raw.trim());
      if (d != null) return DateTime(d.year, d.month, d.day);
    }
    return DateTime(fallback.year, fallback.month, fallback.day);
  }

  static int _parseMinutes(dynamic raw) {
    if (raw is int) return raw.clamp(5, 600);
    if (raw is double) return raw.round().clamp(5, 600);
    if (raw is String) {
      final n = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
      if (n != null) return n.clamp(5, 600);
    }
    return 30;
  }
}
