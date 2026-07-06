import '../models/record.dart';

/// ============================================================
/// 记录仓库【抽象接口】——业务只依赖它。
/// 第一版本地实现 LocalRecordRepository（sqflite）。
/// 【扩展点·上云】未来 CloudRecordRepository 实现同接口即可替换。
/// ============================================================
abstract class RecordRepository {
  /// 按时间倒序返回记录，可按类型筛选（type 为 null 返回全部）。
  Future<List<RecordEntry>> getRecords({String? type});
  Future<RecordEntry?> getRecord(String id);
  Future<void> upsertRecord(RecordEntry record);
  Future<void> deleteRecord(String id);

  /// 近期记录（喂给 AI 排计划 / 复盘洞察，实现“记录→计划”的打通）。
  Future<List<RecordEntry>> getRecentRecords(DateTime since, {int limit = 30});
}
