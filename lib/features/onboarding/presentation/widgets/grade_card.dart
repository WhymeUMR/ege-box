import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Крупная карточка-выбор класса. Используется в онбординге.
class GradeCard extends StatelessWidget {
  const GradeCard({
    super.key,
    required this.grade,
    required this.selected,
    required this.onTap,
  });

  final int grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : AppColors.text.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.text.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Text(
                  '$grade',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.background : AppColors.text,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'класс',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.background.withValues(alpha: 0.9)
                        : AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('selected'),
                          color: AppColors.background,
                          size: 26,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          key: const ValueKey('idle'),
                          color: AppColors.text.withValues(alpha: 0.25),
                          size: 26,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
