/// DeepSeek AI 配置（只存本地）
class AiConfig {
  final String apiKey;
  final String baseUrl;
  final String model;

  const AiConfig({
    this.apiKey = '',
    this.baseUrl = 'https://api.deepseek.com/v1/chat/completions',
    this.model = 'deepseek-chat',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;

  AiConfig copyWith({String? apiKey, String? baseUrl, String? model}) =>
      AiConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
      );

  Map<String, dynamic> toJson() =>
      {'apiKey': apiKey, 'baseUrl': baseUrl, 'model': model};

  factory AiConfig.fromJson(Map<String, dynamic> j) => AiConfig(
        apiKey: (j['apiKey'] as String?) ?? '',
        baseUrl: (j['baseUrl'] as String?) ??
            'https://api.deepseek.com/v1/chat/completions',
        model: (j['model'] as String?) ?? 'deepseek-chat',
      );
}

/// 我的约束设置（AI 排计划必读的硬性条件）
class UserConstraints {
  final String wakeTime; // 起床
  final String sleepTime; // 睡觉
  final String workStart; // 上班
  final String workEnd; // 下班
  final int commuteMinutes; // 通勤耗时（分钟，单程）
  final String freeSlots; // 每天可自由支配的时段描述
  final int freeMinutesPerDay; // 每天可自由支配总时长（分钟）
  final String extraConstraints; // 特殊约束（健身房开放时间、周末规则等）

  const UserConstraints({
    this.wakeTime = '07:00',
    this.sleepTime = '23:00',
    this.workStart = '09:00',
    this.workEnd = '18:00',
    this.commuteMinutes = 30,
    this.freeSlots = '晚上 19:30–22:30',
    this.freeMinutesPerDay = 120,
    this.extraConstraints = '',
  });

  UserConstraints copyWith({
    String? wakeTime,
    String? sleepTime,
    String? workStart,
    String? workEnd,
    int? commuteMinutes,
    String? freeSlots,
    int? freeMinutesPerDay,
    String? extraConstraints,
  }) =>
      UserConstraints(
        wakeTime: wakeTime ?? this.wakeTime,
        sleepTime: sleepTime ?? this.sleepTime,
        workStart: workStart ?? this.workStart,
        workEnd: workEnd ?? this.workEnd,
        commuteMinutes: commuteMinutes ?? this.commuteMinutes,
        freeSlots: freeSlots ?? this.freeSlots,
        freeMinutesPerDay: freeMinutesPerDay ?? this.freeMinutesPerDay,
        extraConstraints: extraConstraints ?? this.extraConstraints,
      );

  Map<String, dynamic> toJson() => {
        'wakeTime': wakeTime,
        'sleepTime': sleepTime,
        'workStart': workStart,
        'workEnd': workEnd,
        'commuteMinutes': commuteMinutes,
        'freeSlots': freeSlots,
        'freeMinutesPerDay': freeMinutesPerDay,
        'extraConstraints': extraConstraints,
      };

  factory UserConstraints.fromJson(Map<String, dynamic> j) => UserConstraints(
        wakeTime: (j['wakeTime'] as String?) ?? '07:00',
        sleepTime: (j['sleepTime'] as String?) ?? '23:00',
        workStart: (j['workStart'] as String?) ?? '09:00',
        workEnd: (j['workEnd'] as String?) ?? '18:00',
        commuteMinutes: (j['commuteMinutes'] as int?) ?? 30,
        freeSlots: (j['freeSlots'] as String?) ?? '',
        freeMinutesPerDay: (j['freeMinutesPerDay'] as int?) ?? 120,
        extraConstraints: (j['extraConstraints'] as String?) ?? '',
      );

  /// 组装成给 AI 的硬性约束文本
  String toPromptText() {
    return '作息：起床$wakeTime，睡觉$sleepTime，上班$workStart，下班$workEnd，'
        '单程通勤约$commuteMinutes分钟。\n'
        '每天可自由支配时段：$freeSlots，总时长约$freeMinutesPerDay分钟。\n'
        '${extraConstraints.trim().isEmpty ? '' : '特殊约束：$extraConstraints'}';
  }
}
