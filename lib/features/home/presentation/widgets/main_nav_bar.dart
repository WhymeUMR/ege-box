import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Пять секций главного меню.
enum MainNavItem { tasks, stats, materials, mocks, profile }

extension MainNavItemX on MainNavItem {
  IconData get icon {
    switch (this) {
      case MainNavItem.tasks:
        return Icons.checklist_rounded;
      case MainNavItem.stats:
        return Icons.bar_chart_rounded;
      case MainNavItem.materials:
        return Icons.menu_book_outlined;
      case MainNavItem.mocks:
        return Icons.fact_check_outlined;
      case MainNavItem.profile:
        return Icons.person_outline_rounded;
    }
  }

  String get label {
    switch (this) {
      case MainNavItem.tasks:
        return 'Задачи';
      case MainNavItem.stats:
        return 'Статистика';
      case MainNavItem.materials:
        return 'Материалы';
      case MainNavItem.mocks:
        return 'Пробники';
      case MainNavItem.profile:
        return 'Личный кабинет';
    }
  }
}

/// Жидкий стеклянный nav-bar с подвижной «пилюлей» — портирован 1 в 1
/// из cloudz_app, расширен с 3 до 5 секций.
class MainNavBar extends StatefulWidget {
  const MainNavBar({
    super.key,
    required this.selectedItem,
    required this.onSelected,
  });

  final MainNavItem selectedItem;
  final ValueChanged<MainNavItem> onSelected;

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  double? _dragLeft;
  var _isDragging = false;

  MainNavItem _itemForLeft(double left, double slotWidth, double activeWidth) {
    final pillCenter = left + (activeWidth / 2);
    final index = (pillCenter / slotWidth).floor().clamp(
      0,
      MainNavItem.values.length - 1,
    );
    return MainNavItem.values[index];
  }

  double _leftForItem(
    MainNavItem item,
    double slotWidth,
    double padding,
    double activeWidth,
    double maxWidth,
  ) {
    final index = MainNavItem.values.indexOf(item);
    final edgeInset = padding + 6;

    if (index == 0) {
      return edgeInset;
    }
    if (index == MainNavItem.values.length - 1) {
      return maxWidth - edgeInset - activeWidth;
    }

    return padding + (index * slotWidth) + ((slotWidth - activeWidth) / 2);
  }

  double _clampLeft(
    double left,
    double maxWidth,
    double padding,
    double activeWidth,
  ) {
    final minLeft = padding;
    final maxLeft = maxWidth - padding - activeWidth;
    return left.clamp(minLeft, maxLeft);
  }

  void _beginDrag(
    Offset localPosition,
    double maxWidth,
    double padding,
    double activeWidth,
  ) {
    setState(() {
      _isDragging = true;
      _dragLeft = _clampLeft(
        localPosition.dx - (activeWidth / 2),
        maxWidth,
        padding,
        activeWidth,
      );
    });
  }

  void _updateDrag(
    Offset localPosition,
    double maxWidth,
    double padding,
    double activeWidth,
  ) {
    setState(() {
      _dragLeft = _clampLeft(
        localPosition.dx - (activeWidth / 2),
        maxWidth,
        padding,
        activeWidth,
      );
    });
  }

  void _endDrag(
    double slotWidth,
    double padding,
    double activeWidth,
    double maxWidth,
  ) {
    final currentLeft =
        _dragLeft ??
        _leftForItem(
          widget.selectedItem,
          slotWidth,
          padding,
          activeWidth,
          maxWidth,
        );
    final item = _itemForLeft(currentLeft - padding, slotWidth, activeWidth);
    widget.onSelected(item);
    setState(() {
      _isDragging = false;
      _dragLeft = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = AppColors.text;
    const outerHeight = 64.0;

    return SizedBox(
      height: outerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const padding = 6.0;
          final slotWidth =
              (constraints.maxWidth - (padding * 2)) /
              MainNavItem.values.length;
          // активная «пилюля» чуть уже слота, чтобы влезало 5 штук
          final baseActive = (slotWidth - 4).clamp(48.0, 70.0);
          final activeWidth = _isDragging ? baseActive + 8 : baseActive;
          final restingLeft = _leftForItem(
            widget.selectedItem,
            slotWidth,
            padding,
            activeWidth,
            constraints.maxWidth,
          );
          final activeLeft =
              _dragLeft ??
              _clampLeft(
                restingLeft,
                constraints.maxWidth,
                padding,
                activeWidth,
              );
          final liquidCenter = activeLeft + (activeWidth / 2);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _beginDrag(
              details.localPosition,
              constraints.maxWidth,
              padding,
              activeWidth,
            ),
            onTapUp: (_) =>
                _endDrag(slotWidth, padding, activeWidth, constraints.maxWidth),
            onTapCancel: () =>
                _endDrag(slotWidth, padding, activeWidth, constraints.maxWidth),
            onHorizontalDragStart: (details) => _beginDrag(
              details.localPosition,
              constraints.maxWidth,
              padding,
              activeWidth,
            ),
            onHorizontalDragUpdate: (details) => _updateDrag(
              details.localPosition,
              constraints.maxWidth,
              padding,
              activeWidth,
            ),
            onHorizontalDragEnd: (_) =>
                _endDrag(slotWidth, padding, activeWidth, constraints.maxWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(90),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    color: primary.withValues(
                      alpha: isDark ? 0.09 : 0.075,
                    ),
                    border: Border.all(
                      color: primary.withValues(
                        alpha: isDark ? 0.13 : 0.10,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.22 : 0.06,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: activeLeft,
                        top: 6,
                        width: activeWidth,
                        height: 52,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(90),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(
                              sigmaX: _isDragging ? 18 : 14,
                              sigmaY: _isDragging ? 18 : 14,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(90),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    primary.withValues(
                                      alpha: isDark ? 0.04 : 0.03,
                                    ),
                                    primary.withValues(
                                      alpha: isDark ? 0.12 : 0.09,
                                    ),
                                    primary.withValues(
                                      alpha: isDark ? 0.04 : 0.03,
                                    ),
                                  ],
                                ),
                                border: Border.all(
                                  color: primary.withValues(
                                    alpha: isDark ? 0.14 : 0.10,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                      alpha: isDark ? 0.05 : 0.09,
                                    ),
                                    blurRadius: 7,
                                    spreadRadius: -2,
                                    offset: const Offset(0, -1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: MainNavItem.values.indexed.map((entry) {
                            final index = entry.$1;
                            final item = entry.$2;
                            final iconCenter =
                                padding + (slotWidth * index) + (slotWidth / 2);
                            final distance = (liquidCenter - iconCenter).abs();
                            final influence = (1 - (distance / slotWidth))
                                .clamp(0.0, 1.0);
                            final iconScale =
                                1 + (influence * (_isDragging ? 0.22 : 0.12));
                            final iconSize =
                                _lerp(20, 23, influence);
                            final iconColor = Color.lerp(
                              primary.withValues(
                                alpha: isDark ? 0.52 : 0.48,
                              ),
                              AppColors.primary,
                              influence,
                            )!;

                            return Expanded(
                              child: Center(
                                child: AnimatedScale(
                                  scale: iconScale,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    item.icon,
                                    size: iconSize,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
