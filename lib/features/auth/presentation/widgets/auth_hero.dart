import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Заголовок + подзаголовок с маленьким логотипом. Сжимается, когда
/// появляется клавиатура.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // На маленькой высоте (клавиатура открыта) прячем лого.
        final showLogo = constraints.maxHeight >= 160;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                opacity: showLogo ? 1 : 0,
                child: showLogo
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Image.asset(
                          'assets/logo.png',
                          height:
                              constraints.maxHeight.clamp(60, 120) * 0.55,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: AppColors.text,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: AppColors.text.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        );
      },
    );
  }
}
