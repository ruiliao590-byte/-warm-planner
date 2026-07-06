import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 丝滑打钩勾选框：平滑填充 + 对勾描画动画。点一下即完成。
class AnimatedCheck extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final double size;

  const AnimatedCheck({
    super.key,
    required this.checked,
    this.onChanged,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!checked),
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: AppDurations.curve,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: checked ? AppColors.accent : AppColors.textMuted,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          duration: AppDurations.normal,
          curve: Curves.easeOutBack,
          scale: checked ? 1 : 0,
          child: CustomPaint(
            painter: _CheckPainter(),
            size: Size(size, size),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.74, h * 0.34);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
