import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';

const _textStyle = TextStyle(
  fontFamily: 'SpaceGrotesk',
  fontSize: 16,
  fontWeight: FontWeight.w600,
  height: 1.15,
);

class PillPrimaryButton extends StatelessWidget {
  const PillPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    void handlePress() {
      if (onPressed == null) return;
      AppHaptics.tap();
      onPressed!.call();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed == null ? null : handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: _textStyle,
        ),
        child: Text(label),
      ),
    );
  }
}

class PillOutlinedButton extends StatelessWidget {
  const PillOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    void handlePress() {
      if (onPressed == null) return;
      AppHaptics.tap();
      onPressed!.call();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed == null ? null : handlePress,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: _textStyle,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Кнопка «Войти через Telegram». Сохраняем общую pill-форму, фон —
/// палеточный secondary (Medium Purple), иконка и текст — background.
class PillTelegramButton extends StatelessWidget {
  const PillTelegramButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    void handlePress() {
      if (onPressed == null) return;
      AppHaptics.tap();
      onPressed!.call();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed == null ? null : handlePress,
        icon: const FaIcon(
          FontAwesomeIcons.telegram,
          size: 22,
          color: AppColors.background,
        ),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.background,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: _textStyle,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }
}
