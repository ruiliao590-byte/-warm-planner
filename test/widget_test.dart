// 基础冒烟测试：确认主题与核心组件可正常构建。
// 说明：整个 App 依赖本地 sqflite 数据库，需在真机/模拟器上运行，
// 因此这里只做不依赖数据库的轻量渲染测试。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warm_planner/core/theme/app_theme.dart';
import 'package:warm_planner/features/shared/common_widgets.dart';

void main() {
  testWidgets('SmoothProgressBar 能正常渲染', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(child: SmoothProgressBar(value: 0.5)),
      ),
    ));
    expect(find.byType(SmoothProgressBar), findsOneWidget);
  });
}
