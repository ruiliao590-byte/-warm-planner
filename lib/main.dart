import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/home_shell.dart';
import 'core/theme/app_theme.dart';
import 'services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化中文日期本地化数据（星期、月份等）
  await initializeDateFormatting('zh_CN', null);
  // 初始化本地通知（任务定时提醒）
  await NotificationService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // 移动端竖屏优先
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: WarmPlannerApp()));
}

class WarmPlannerApp extends StatelessWidget {
  const WarmPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '计划 · 记录',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 【扩展点】未来深色主题：darkTheme + themeMode 即可扩展
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
