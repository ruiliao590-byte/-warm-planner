import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 平滑增长的进度条（不跳变，有过渡动画）——目标成就感来源。
class SmoothProgressBar extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final double height;
  const SmoothProgressBar({super.key, required this.value, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: AppDurations.slow,
        curve: AppDurations.curve,
        builder: (context, v, _) {
          return Stack(
            children: [
              Container(height: height, color: AppColors.progressTrack),
              FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.accentSoft],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 温暖风格卡片（柔和阴影 + 极细描边 + 中等圆角）
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.subtle,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        splashColor: AppColors.accent.withOpacity(0.06),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// 主按钮：点击有细腻缩放反馈（手感高级不廉价）
class PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;
  final IconData? icon;
  final bool expand;

  const PressableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.filled = true,
    this.loading = false,
    this.icon,
    this.expand = false,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final label = DefaultTextStyle(
      style: TextStyle(
        color: widget.filled ? Colors.white : AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      child: widget.child,
    );

    Widget inner = widget.loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(
                  widget.filled ? Colors.white : AppColors.accent),
            ),
          )
        : Row(
            mainAxisSize:
                widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: 20,
                    color:
                        widget.filled ? Colors.white : AppColors.accent),
                const SizedBox(width: 8),
              ],
              Flexible(child: label),
            ],
          );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: AppDurations.fast,
        curve: AppDurations.curve,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          decoration: BoxDecoration(
            color: widget.filled
                ? (enabled ? AppColors.accent : AppColors.accentSoft)
                : Colors.transparent,
            borderRadius: AppRadius.button,
            border: widget.filled
                ? null
                : Border.all(color: AppColors.cardBorder),
          ),
          child: Center(child: inner),
        ),
      ),
    );
  }
}

/// 空状态提示
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// AI 未配置的友好提示条
class AiNotConfiguredBanner extends StatelessWidget {
  final VoidCallback onGoSettings;
  const AiNotConfiguredBanner({super.key, required this.onGoSettings});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.accentWash,
      onTap: onGoSettings,
      child: Row(
        children: const [
          Icon(Icons.auto_awesome_outlined, color: AppColors.accent),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '还没配置 DeepSeek，AI 功能暂不可用。点这里去「设置」填写 API Key。',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

/// 轻微渐入 + 上浮的出现动画（列表/卡片加载时让界面“活”起来）
class FadeInUp extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeInUp({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow,
      curve: AppDurations.curve,
      builder: (context, v, child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 分类/类型小标签
class TinyTag extends StatelessWidget {
  final String text;
  final Color color;
  const TinyTag({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
