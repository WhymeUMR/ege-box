import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Прогресс онбординга: подпись шага слева и непрерывная линия из [total]
/// сегментов, у которой при появлении плавно «доезжает» заливка от
/// предыдущего шага к текущему.
class StepProgress extends StatefulWidget {
  const StepProgress({
    super.key,
    required this.label,
    required this.current,
    required this.total,
  });

  final String label;
  final int current;
  final int total;

  @override
  State<StepProgress> createState() => _StepProgressState();
}

class _StepProgressState extends State<StepProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late Animation<double> _value;

  @override
  void initState() {
    super.initState();
    // Стартуем заливку от (current-1) и доводим до current — выглядит так,
    // будто прогресс «продолжился» с прошлого экрана. Для первого шага
    // едем от 0.
    final from = (widget.current - 1).clamp(0, widget.total).toDouble();
    final to = widget.current.toDouble();
    _value = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic),
    );
    // Маленькая задержка, чтобы анимация совпадала с приходом страницы.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctl.forward();
    });
  }

  @override
  void didUpdateWidget(covariant StepProgress old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current || old.total != widget.total) {
      _value = Tween<double>(
        begin: old.current.toDouble(),
        end: widget.current.toDouble(),
      ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic));
      _ctl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.text.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 6,
          child: AnimatedBuilder(
            animation: _value,
            builder: (context, _) {
              return CustomPaint(
                painter: _SegmentedBarPainter(
                  progress: _value.value,
                  total: widget.total,
                  filledColor: AppColors.primary,
                  trackColor: AppColors.text.withValues(alpha: 0.12),
                  gap: 8,
                  radius: 3,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Рисует «капсульные» сегменты-трек и поверх плавную заливку, которая
/// идёт сквозь все сегменты пропорционально [progress] (от 0 до total).
class _SegmentedBarPainter extends CustomPainter {
  _SegmentedBarPainter({
    required this.progress,
    required this.total,
    required this.filledColor,
    required this.trackColor,
    required this.gap,
    required this.radius,
  });

  final double progress;
  final int total;
  final Color filledColor;
  final Color trackColor;
  final double gap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final segWidth = (size.width - gap * (total - 1)) / total;
    final trackPaint = Paint()..color = trackColor;
    final fillPaint = Paint()..color = filledColor;
    final r = Radius.circular(radius);

    for (var i = 0; i < total; i++) {
      final left = i * (segWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, segWidth, size.height),
        r,
      );
      canvas.drawRRect(rect, trackPaint);

      // Сколько прогресса приходится на этот сегмент: 0..1.
      final segProgress = (progress - i).clamp(0.0, 1.0);
      if (segProgress > 0) {
        final fillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, segWidth * segProgress, size.height),
          r,
        );
        canvas.drawRRect(fillRect, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedBarPainter old) =>
      old.progress != progress ||
      old.total != total ||
      old.filledColor != filledColor ||
      old.trackColor != trackColor;
}
