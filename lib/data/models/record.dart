/// 记录模型（生态 B：记录 / 沉淀）——双模式
///
/// - review（复盘型/踩坑）：情境 → 遇到的问题 → 我的分析 → 下次怎么办
/// - inspiration（灵感型/好想法）：我想到了什么 → 触发场景/背景
///
/// 【扩展点】tags：预留标签字段（第二版做搜索与标签，当前不用）。
/// 【扩展点】userId：预留多账号。
class RecordEntry {
  final String id;
  final String userId; // 预留：未来多账号
  final String type; // review / inspiration

  // 复盘型字段
  final String situation; // 情境
  final String problem; // 遇到的问题
  final String analysis; // 我的分析
  final String nextAction; // 下次怎么办

  // 灵感型字段
  final String idea; // 我想到了什么
  final String triggerContext; // 触发场景/背景

  final String aiSuggestion; // AI 给的建议（保存在记录下方）
  final String tags; // 【扩展点】预留标签（逗号分隔，第二版启用）
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecordEntry({
    required this.id,
    this.userId = 'local',
    required this.type,
    this.situation = '',
    this.problem = '',
    this.analysis = '',
    this.nextAction = '',
    this.idea = '',
    this.triggerContext = '',
    this.aiSuggestion = '',
    this.tags = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReview => type == 'review';
  bool get isInspiration => type == 'inspiration';

  /// 用于列表预览的标题
  String get previewTitle {
    if (isReview) {
      return problem.isNotEmpty
          ? problem
          : (situation.isNotEmpty ? situation : '未命名复盘');
    }
    return idea.isNotEmpty ? idea : '未命名灵感';
  }

  /// 用于喂给 AI / 复盘洞察的纯文本摘要
  String toPlainText() {
    if (isReview) {
      return '【复盘】情境：$situation；问题：$problem；分析：$analysis；下次：$nextAction';
    }
    return '【灵感】想法：$idea；背景：$triggerContext';
  }

  RecordEntry copyWith({
    String? situation,
    String? problem,
    String? analysis,
    String? nextAction,
    String? idea,
    String? triggerContext,
    String? aiSuggestion,
    String? tags,
    DateTime? updatedAt,
  }) {
    return RecordEntry(
      id: id,
      userId: userId,
      type: type,
      situation: situation ?? this.situation,
      problem: problem ?? this.problem,
      analysis: analysis ?? this.analysis,
      nextAction: nextAction ?? this.nextAction,
      idea: idea ?? this.idea,
      triggerContext: triggerContext ?? this.triggerContext,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'situation': situation,
        'problem': problem,
        'analysis': analysis,
        'next_action': nextAction,
        'idea': idea,
        'trigger_context': triggerContext,
        'ai_suggestion': aiSuggestion,
        'tags': tags,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory RecordEntry.fromMap(Map<String, dynamic> m) => RecordEntry(
        id: m['id'] as String,
        userId: (m['user_id'] as String?) ?? 'local',
        type: m['type'] as String,
        situation: (m['situation'] as String?) ?? '',
        problem: (m['problem'] as String?) ?? '',
        analysis: (m['analysis'] as String?) ?? '',
        nextAction: (m['next_action'] as String?) ?? '',
        idea: (m['idea'] as String?) ?? '',
        triggerContext: (m['trigger_context'] as String?) ?? '',
        aiSuggestion: (m['ai_suggestion'] as String?) ?? '',
        tags: (m['tags'] as String?) ?? '',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}
