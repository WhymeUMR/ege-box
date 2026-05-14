import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Строка-карточка предмета ЕГЭ для вертикального списка.
/// В выбранном состоянии заливается primary, в обычном — светлый фон с обводкой.
/// Иконка тянется по сети ([iconUrl]); если не загрузилась — показывается [emoji].
class SubjectChip extends StatelessWidget {
  const SubjectChip({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.iconUrl,
    this.emoji,
    this.disabled = false,
  });

  final String title;
  final String iconUrl;
  final String? emoji;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.primary
        : AppColors.text.withValues(alpha: disabled ? 0.02 : 0.04);
    final fg = selected ? AppColors.background : AppColors.text;
    final borderColor = selected
        ? AppColors.primary
        : AppColors.text.withValues(alpha: 0.1);

    return Opacity(
      opacity: disabled && !selected ? 0.45 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled && !selected ? null : onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _Icon(
                    url: iconUrl,
                    emojiFallback: emoji,
                    background: selected
                        ? AppColors.background
                        : AppColors.background,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fg,
                        height: 1.2,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.background
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.background
                            : AppColors.text.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({
    required this.url,
    required this.emojiFallback,
    required this.background,
  });

  final String url;
  final String? emojiFallback;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.text.withValues(alpha: 0.4),
              ),
            );
          },
          errorBuilder: (context, _, _) => Text(
            emojiFallback ?? '📚',
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
