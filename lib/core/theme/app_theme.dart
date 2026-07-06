import 'package:flutter/material.dart';

/// ============================================================
/// 主题系统（集中管理）——温暖米白风 · 参照 Claude 官网气质
/// 暖白打底 + 暖橘点睛 + 留白呼吸 + 动画柔滑
///
/// 【扩展点】未来加深色主题：在此新增 darkColors / buildDarkTheme()，
/// 全 App 只依赖这里的常量，改动集中、不散落。
/// ============================================================

/// 暖色调、低饱和、克制的配色
class AppColors {
  AppColors._();

  // 背景：暖白 / 奶油色（不是纯白，也不是冷灰）
  static const Color background = Color(0xFFFAF9F5); // 主背景暖白
  static const Color backgroundAlt = Color(0xFFF5F1EA); // 略深奶油色分区

  // 卡片：略带层次的暖白 + 极细描边 + 柔和阴影
  static const Color card = Color(0xFFFFFDF9);
  static const Color cardBorder = Color(0xFFECE7DD);

  // 主强调色：Claude 标志性暖橘 / 赤陶色（terracotta）——只用在关键处
  static const Color accent = Color(0xFFD97757);
  static const Color accentSoft = Color(0xFFE6A088); // 浅一档，用于渐变/禁用
  static const Color accentWash = Color(0xFFF6E7DF); // 极浅背景（选中态底色）

  // 文字：偏暖的深灰（不是纯黑，读起来柔和）
  static const Color textStrong = Color(0xFF2B2B28);
  static const Color textPrimary = Color(0xFF3D3D3A);
  static const Color textSecondary = Color(0xFF6B6B63);
  static const Color textMuted = Color(0xFF9A968C);

  // 进度条
  static const Color progressTrack = Color(0xFFEAE5DB);
  static const Color progressFill = accent;

  // 功能色（克制）
  static const Color success = Color(0xFF6E9E7C);
  static const Color danger = Color(0xFFC7644E);
  static const Color divider = Color(0xFFECE7DD);

  // 记录类型点缀
  static const Color reviewTag = Color(0xFFB98756); // 复盘型（踩坑）
  static const Color inspirationTag = Color(0xFF8B9A6B); // 灵感型（好想法）
}

/// 圆角：舒服的中等圆角（12–16px），整体圆润温和
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14; // 按钮 / 输入框
  static const double lg = 16; // 卡片
  static const double xl = 22;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get input => BorderRadius.circular(md);
}

/// 间距：大量留白、有呼吸感
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double page = 20; // 页面左右安全边距
}

/// 动画：快而柔、克制、有目的（几百毫秒内）
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve curveIn = Curves.easeInCubic;
}

/// 柔和阴影（不要重投影）
class AppShadows {
  AppShadows._();
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF7A6A55).withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: const Color(0xFF7A6A55).withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      primary: AppColors.accent,
      surface: AppColors.background,
    ).copyWith(
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashColor: AppColors.accent.withOpacity(0.08),
      highlightColor: AppColors.accent.withOpacity(0.05),
      dividerColor: AppColors.divider,
      // 干净现代的无衬线字体（系统高质量无衬线：Android 用 Roboto）
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textStrong,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundAlt,
        selectedColor: AppColors.accentWash,
        side: const BorderSide(color: AppColors.cardBorder),
        labelStyle: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textStrong,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.progressTrack,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    TextStyle t(double size, FontWeight w, Color c,
            {double h = 1.4, double ls = 0}) =>
        TextStyle(
            fontSize: size,
            fontWeight: w,
            color: c,
            height: h,
            letterSpacing: ls);
    return base.copyWith(
      headlineLarge: t(28, FontWeight.w700, AppColors.textStrong, h: 1.25),
      headlineMedium: t(24, FontWeight.w600, AppColors.textStrong, h: 1.3),
      titleLarge: t(20, FontWeight.w600, AppColors.textStrong, h: 1.35),
      titleMedium: t(17, FontWeight.w600, AppColors.textPrimary, h: 1.4),
      bodyLarge: t(16, FontWeight.w400, AppColors.textPrimary, h: 1.55),
      bodyMedium: t(15, FontWeight.w400, AppColors.textPrimary, h: 1.55),
      bodySmall: t(13, FontWeight.w400, AppColors.textSecondary, h: 1.5),
      labelLarge: t(15, FontWeight.w600, AppColors.textPrimary),
      labelSmall: t(12, FontWeight.w500, AppColors.textMuted),
    );
  }
}
