import '../models/app_settings.dart';

/// ============================================================
/// 设置仓库【抽象接口】——AI 配置 + 我的约束条件 + 通用 KV。
/// 第一版本地实现 LocalSettingsRepository（sqflite）。
/// ============================================================
abstract class SettingsRepository {
  Future<AiConfig> getAiConfig();
  Future<void> saveAiConfig(AiConfig config);

  Future<UserConstraints> getConstraints();
  Future<void> saveConstraints(UserConstraints constraints);

  Future<String?> getRaw(String key);
  Future<void> setRaw(String key, String value);
}
