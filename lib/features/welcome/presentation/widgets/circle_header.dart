import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import 'typewriter_text.dart';

/// Большой круг фирменного цвета. Верхняя часть круга (и его боковые края)
/// обрезаются по границе хедера, поэтому видна только нижняя «купольная» дуга.
/// Текст-слоган центрируется по видимой области.
class CircleHeader extends StatelessWidget {
  const CircleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    // Сам круг крупнее — диаметр = 2.2 ширины экрана.
    final size = media.width * 2.2;
    // Видимая часть круга = ~1.075 от его высоты (фактически весь купол):
    // верх по-прежнему обрезается ClipRect, а круг опущен ещё ниже.
    final maxVisible = math.max(320.0, media.height - 220);
    final visibleHeight = (size * 1.075)
        .clamp(320.0, math.min(size, maxVisible))
        .toDouble();
    // Скрываем сверху всё, что не помещается, — верх круга не виден.
    final hiddenTop = size - visibleHeight;

    return SizedBox(
      width: double.infinity,
      height: visibleHeight,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.bottomCenter,
          children: [
            // Сам круг: смещён вверх и вбок так, чтобы был виден только купол.
            Positioned(
              top: -hiddenTop,
              left: (media.width - size) / 2,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Текст центрирован по видимой области купола.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 240),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo_main.png',
                        height: math.min(media.width * 0.28, 120),
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        // Фиксируем высоту, чтобы текст при печати/стирании
                        // не «прыгал» вверх-вниз по мере смены длины фразы.
                        height: 132,
                        child: TypewriterText(
                          phrases: AppStrings.welcomeTaglines,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: AppColors.background,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
