/// 目标模型（生态 A：计划）
///
/// 【扩展点】userId：当前单用户，恒为 'local'。未来接账号系统时按 userId 隔离数据，
/// 数据层与业务层无需大改。
class Goal {
  final String id;
  final String userId; // 预留：未来多账号
  final String name;
  final String category; // 运动健身 / 学习技能 / 休闲 / 工作（可扩展）
  final String type; // short（短期）/ long（长期）
  final String description;
  final DateTime? deadline; // 截止时间（可选）
  final bool isCompleted;
  final DateTime createdAt;

  const Goal({
    required this.id,
    this.userId = 'local',
    required this.name,
    required this.category,
    this.type = 'short',
    this.description = '',
    this.deadline,
    this.isCompleted = false,
    required this.createdAt,
  });

  Goal copyWith({
    String? name,
    String? category,
    String? type,
    String? description,
    DateTime? deadline,
    bool? clearDeadline,
    bool? isCompleted,
  }) {
    return Goal(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      description: description ?? this.description,
      deadline: (clearDeadline ?? false) ? null : (deadline ?? this.deadline),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'category': category,
        'type': type,
        'description': description,
        'deadline': deadline?.millisecondsSinceEpoch,
        'is_completed': isCompleted ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as String,
        userId: (m['user_id'] as String?) ?? 'local',
        name: m['name'] as String,
        category: m['category'] as String,
        type: (m['type'] as String?) ?? 'short',
        description: (m['description'] as String?) ?? '',
        deadline: m['deadline'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['deadline'] as int),
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  static const List<String> categories = [
    '运动健身',
    '学习技能',
    '休闲',
    '工作',
  ];
}

/// 目标 + 其进度统计（进度 = 已完成任务数 / 计划任务总数）
class GoalWithProgress {
  final Goal goal;
  final int totalTasks;
  final int completedTasks;

  const GoalWithProgress({
    required this.goal,
    required this.totalTasks,
    required this.completedTasks,
  });

  /// 自动计算的进度 0.0 ~ 1.0
  double get progress =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  int get progressPercent => (progress * 100).round();
}
