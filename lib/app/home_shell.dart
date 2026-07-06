import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/goals/goals_screen.dart';
import '../features/records/records_screen.dart';
import '../features/review/review_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/today_screen.dart';

/// 主框架：底部导航切换 今日 / 目标 / 记录 / 复盘 / 设置。
/// 页面切换用柔和淡入淡出过渡，不生硬瞬切。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _pages = [
    TodayScreen(),
    GoalsScreen(),
    RecordsScreen(),
    ReviewScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: AppDurations.curve,
        switchOutCurve: AppDurations.curveIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.wb_sunny_outlined),
                activeIcon: Icon(Icons.wb_sunny),
                label: '今日'),
            BottomNavigationBarItem(
                icon: Icon(Icons.flag_outlined),
                activeIcon: Icon(Icons.flag),
                label: '目标'),
            BottomNavigationBarItem(
                icon: Icon(Icons.edit_note_outlined),
                activeIcon: Icon(Icons.edit_note),
                label: '记录'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights),
                label: '复盘'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: '设置'),
          ],
        ),
      ),
    );
  }
}

/// 柔和的页面进入过渡（用于 push 详情页）——淡入 + 轻微上滑。
Route<T> softRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppDurations.normal,
    reverseTransitionDuration: AppDurations.fast,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation, curve: AppDurations.curve)),
          child: child,
        ),
      );
    },
  );
}
