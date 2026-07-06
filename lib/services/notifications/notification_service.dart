import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/task.dart';

/// 本地通知服务：任务定时提醒 · 到点推送。
///
/// 【扩展方向】这是需求里预留的「定时提醒推送」。任务模型的 reminderTime
/// 字段即为提醒时间；此服务负责在设定时间弹出安卓本地通知。
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static const String _channelId = 'task_reminders';
  static const String _channelName = '任务提醒';
  static const String _channelDesc = '任务到点提醒推送';

  /// 应用启动时调用一次：初始化时区数据与通知插件。
  static Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    // 固定使用中国时区（单一时区、无夏令时）。
    // 【扩展点】未来若要支持跨时区，可接入 flutter_timezone 动态获取本地时区。
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _inited = true;
  }

  /// 请求通知权限（Android 13+ 需运行时授权）+ 精确闹钟权限。
  /// 返回是否已获得通知权限。
  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    // 精确闹钟（Android 12+）：用于到点准时提醒
    await android.requestExactAlarmsPermission();
    return granted ?? true;
  }

  /// 由任务 id（UUID 字符串）稳定映射成通知用的正整数 id。
  static int notificationId(String taskId) => taskId.hashCode & 0x7fffffff;

  /// 为某个时间点安排一条提醒。过去的时间会被忽略。
  static Future<void> schedule({
    required String taskId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
      // 已过去，直接不排（并清掉可能存在的旧的同 id 提醒）
      await cancelForTask(taskId);
      return;
    }
    await _plugin.zonedSchedule(
      notificationId(taskId),
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelForTask(String taskId) async {
    await init();
    await _plugin.cancel(notificationId(taskId));
  }

  /// 依据任务当前状态同步提醒：有提醒时间且未完成 → 排；否则取消。
  /// UI 每次保存/勾选/删除任务后调用一次即可。
  static Future<void> syncForTask(Task task) async {
    if (task.reminderTime != null && !task.isCompleted) {
      await schedule(
        taskId: task.id,
        title: '任务提醒',
        body: task.title,
        when: task.reminderTime!,
      );
    } else {
      await cancelForTask(task.id);
    }
  }
}
