/// 任务模型（生态 A：计划）
///
/// 清单式、不强绑具体时刻：`suggestedSlot` 仅作参考（如“晚上/通勤路上”），
/// 不锁死几点几分，给执行灵活性。
///
/// 【扩展点】reminderTime：预留“提醒时间”字段。未来接入安卓本地通知，
/// 到点推送，无需改数据模型。
/// 【扩展点】userId：预留多账号。
class Task {
  final String id;
  final String userId; // 预留：未来多账号
  final String? goalId; // 关联目标（极简起步/临时任务可为空）
  final String title;
  final DateTime date; // 计划执行的“哪一天”（按天，不含具体时刻）
  final String suggestedSlot; // 建议时段（参考，可空）
  final int estimatedMinutes; // 预计耗时（分钟）
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? reminderTime; // 【扩展点】未来本地通知提醒时间
  final int orderIndex; // 同一天内排序
  final String note; // 备注
  final DateTime createdAt;

  const Task({
    required this.id,
    this.userId = 'local',
    this.goalId,
    required this.title,
    required this.date,
    this.suggestedSlot = '',
    this.estimatedMinutes = 30,
    this.isCompleted = false,
    this.completedAt,
    this.reminderTime,
    this.orderIndex = 0,
    this.note = '',
    required this.createdAt,
  });

  Task copyWith({
    String? goalId,
    bool? clearGoal,
    String? title,
    DateTime? date,
    String? suggestedSlot,
    int? estimatedMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    bool? clearCompletedAt,
    DateTime? reminderTime,
    bool? clearReminder,
    int? orderIndex,
    String? note,
  }) {
    return Task(
      id: id,
      userId: userId,
      goalId: (clearGoal ?? false) ? null : (goalId ?? this.goalId),
      title: title ?? this.title,
      date: date ?? this.date,
      suggestedSlot: suggestedSlot ?? this.suggestedSlot,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: (clearCompletedAt ?? false)
          ? null
          : (completedAt ?? this.completedAt),
      reminderTime: (clearReminder ?? false)
          ? null
          : (reminderTime ?? this.reminderTime),
      orderIndex: orderIndex ?? this.orderIndex,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'goal_id': goalId,
        'title': title,
        'date': _dayKey(date),
        'suggested_slot': suggestedSlot,
        'estimated_minutes': estimatedMinutes,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'reminder_time': reminderTime?.millisecondsSinceEpoch,
        'order_index': orderIndex,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as String,
        userId: (m['user_id'] as String?) ?? 'local',
        goalId: m['goal_id'] as String?,
        title: m['title'] as String,
        date: _parseDayKey(m['date'] as int),
        suggestedSlot: (m['suggested_slot'] as String?) ?? '',
        estimatedMinutes: (m['estimated_minutes'] as int?) ?? 30,
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        completedAt: m['completed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
        reminderTime: m['reminder_time'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['reminder_time'] as int),
        orderIndex: (m['order_index'] as int?) ?? 0,
        note: (m['note'] as String?) ?? '',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  /// 以“当天 0 点的毫秒数”作为按天存储的 key，便于按日期精确查询。
  static int _dayKey(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
  static DateTime _parseDayKey(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms);

  static int dayKeyOf(DateTime d) => _dayKey(d);
}
