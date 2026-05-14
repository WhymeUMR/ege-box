import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';

/// Жест «свайп с любого места экрана влево-вправо», который уносит
/// текущий маршрут так же, как нативный iOS back-swipe.
///
/// В отличие от наивного варианта (где мы просто двигали child), здесь мы
/// рулим непосредственно контроллером самой [TransitionRoute]: значение
/// контроллера падает с 1 → 0 пропорционально жесту. За счёт этого
/// `transitionsBuilder` маршрута сам красиво анимирует и нашу страницу,
/// и страницу под ней (затемнение, сдвиг и пр.) — без чёрного экрана.
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

class _SwipeBackState extends State<SwipeBack> {
  bool _dragging = false;

  AnimationController? _routeController(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is SwipeablePageRoute) return route.swipeController;
    return null;
  }

  void _onDragStart(DragStartDetails _, AnimationController c) {
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails d, AnimationController c) {
    final w = MediaQuery.of(context).size.width;
    // Делим жест на ширину экрана и уменьшаем значение контроллера
    // (1 — страница на месте, 0 — полностью «уехала»).
    c.value = (c.value - d.delta.dx / w).clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails d, AnimationController c) async {
    if (!_dragging) return;
    _dragging = false;
    final velocity = d.velocity.pixelsPerSecond.dx;
    final progress = 1 - c.value; // насколько уже «утянули» страницу.
    final shouldPop = progress > widget.dismissThreshold ||
        velocity > widget.velocityThreshold;

    if (shouldPop) {
      // Плавно докатываем до 0 и попаем route — Navigator корректно
      // снимет страницу со стека.
      await c.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      await c.animateTo(
        1,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onDragCancel(AnimationController c) {
    if (!_dragging) return;
    _dragging = false;
    c.animateTo(
      1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final controller = _routeController(context);
    final canPop = (route?.canPop ?? false) && controller != null;

    if (!canPop) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (d) => _onDragStart(d, controller),
      onHorizontalDragUpdate: (d) => _onDragUpdate(d, controller),
      onHorizontalDragEnd: (d) => _onDragEnd(d, controller),
      onHorizontalDragCancel: () => _onDragCancel(controller),
      child: widget.child,
    );
  }
}
