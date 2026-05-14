import 'package:flutter/material.dart';

/// Жест «свайп с левого края» — закрывает текущий маршрут так же, как
/// нативный iOS back-swipe: страница следует за пальцем, при достаточном
/// смещении / скорости — улетает вправо и вызывается [Navigator.pop],
/// иначе плавно возвращается на место.
class SwipeBack extends StatefulWidget {
  const SwipeBack({
    super.key,
    required this.child,
    this.dismissThreshold = 0.35,
    this.velocityThreshold = 700,
  });

  final Widget child;

  /// Доля ширины экрана, после которой жест защёлкивается в pop.
  final double dismissThreshold;

  /// Скорость (px/s), при которой жест защёлкивается в pop вне зависимости
  /// от пройденного расстояния.
  final double velocityThreshold;

  @override
  State<SwipeBack> createState() => _SwipeBackState();
}

class _SwipeBackState extends State<SwipeBack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 0,
  );
  bool _popping = false;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final w = MediaQuery.of(context).size.width;
    _progress.value = (_progress.value + d.delta.dx / w).clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    if (_popping) return;
    final velocity = d.velocity.pixelsPerSecond.dx;
    final shouldPop =
        _progress.value > widget.dismissThreshold ||
        velocity > widget.velocityThreshold;

    if (shouldPop) {
      _popping = true;
      await _progress.animateTo(
        1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } else {
      await _progress.animateTo(
        0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onDragCancel() {
    if (_popping) return;
    _progress.animateTo(
      0.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    // Контент страницы — едет за пальцем и слегка теряет непрозрачность.
    final content = AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final w = MediaQuery.of(context).size.width;
        final t = _progress.value;
        return Transform.translate(
          offset: Offset(t * w, 0),
          child: Opacity(opacity: 1 - t * 0.35, child: child),
        );
      },
      child: widget.child,
    );

    if (!canPop) return content;

    // Жест ловится с любой точки экрана.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: content,
    );
  }
}
