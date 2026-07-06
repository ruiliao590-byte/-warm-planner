import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 全局唯一 id 生成器（用于 goal/task/record 主键）。
String newId() => _uuid.v4();
