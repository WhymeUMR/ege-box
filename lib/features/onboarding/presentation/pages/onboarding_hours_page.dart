import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../../../auth/data/auth_service.dart';
import '../widgets/step_progress.dart';

const _minHours = 10;
const _maxHours = 40;

/// Шаг 3 онбординга: сколько часов в неделю пользователь готов уделять
/// подготовке. Ползунок 10–40 + динамическая подсказка под ним.
class OnboardingHoursPage extends StatefulWidget {
  const OnboardingHoursPage({super.key});

  @override
  State<OnboardingHoursPage> createState() => _OnboardingHoursPageState();
}

class _OnboardingHoursPageState extends State<OnboardingHoursPage> {
  // Стартуем с серединки — комфортный темп.
  int _hours = 20;
  bool _busy = false;
  int _lastHapticHours = 20;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthService>().currentUser?.weeklyHours;
    if (saved != null) _hours = saved.clamp(_minHours, _maxHours);
  }

  Future<void> _onFinish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().setWeeklyHours(_hours);
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRouter.onboardingMock);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final name = user?.name ?? '';
    final perDay = _hours / 7;
    final hint = _intensityHint(_hours, perDay);

    return SwipeBack(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepProgress(
                  label: AppStrings.onboardingStepHours,
                  current: 3,
                  total: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.onboardingHoursTitle(name),
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.onboardingHoursSubtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const Spacer(flex: 2),
                _HoursReadout(hours: _hours, perDay: perDay),
                const SizedBox(height: 18),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.text.withValues(alpha: 0.12),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 22,
                    ),
                  ),
                  child: Slider(
                    min: _minHours.toDouble(),
                    max: _maxHours.toDouble(),
                    divisions: _maxHours - _minHours,
                    value: _hours.toDouble(),
                    onChanged: (v) {
                      final next = v.round();
                      if (next != _lastHapticHours) {
                        _lastHapticHours = next;
                        AppHaptics.select();
                      }
                      setState(() => _hours = next);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BoundLabel(text: '$_minHours ч'),
                      _BoundLabel(text: '$_maxHours ч'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Фиксируем высоту, чтобы при смене подсказки кнопка снизу
                // не «дёргалась» вверх-вниз.
                SizedBox(
                  height: 116,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    child: _HintBox(
                      key: ValueKey(hint.tone),
                      label: hint.label,
                      title: hint.title,
                      subtitle: hint.subtitle,
                      tone: hint.tone,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                PillPrimaryButton(
                  label: AppStrings.onboardingFinish,
                  onPressed: _busy ? null : _onFinish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoursReadout extends StatelessWidget {
  const _HoursReadout({required this.hours, required this.perDay});
  final int hours;
  final double perDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: AppColors.text,
              height: 1,
            ),
            children: [
              TextSpan(
                text: '$hours',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const TextSpan(
                text: '  ч/нед',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '≈ ${perDay.toStringAsFixed(1)} ч в день',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _BoundLabel extends StatelessWidget {
  const _BoundLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.text.withValues(alpha: 0.5),
      ),
    );
  }
}

enum _Tone { calm, normal, focused, intense, extreme }

class _Hint {
  const _Hint({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  /// Короткий «таг» в шапке подсказки (заглавный, в духе StepProgress).
  final String label;
  final String title;
  final String subtitle;
  final _Tone tone;
}

_Hint _intensityHint(int hours, double perDay) {
  final perDayStr = perDay.toStringAsFixed(1);
  if (hours <= 13) {
    return _Hint(
      label: 'СПОКОЙНЫЙ ТЕМП',
      title: '~$perDayStr часа в день',
      subtitle:
          'Хватит, чтобы держать форму. Подойдёт, если до экзамена ещё далеко.',
      tone: _Tone.calm,
    );
  }
  if (hours <= 19) {
    return _Hint(
      label: 'БАЗОВЫЙ РИТМ',
      title: '~$perDayStr часа в день',
      subtitle:
          'Комфортная нагрузка — спокойно совмещается со школой и отдыхом.',
      tone: _Tone.normal,
    );
  }
  if (hours <= 25) {
    return _Hint(
      label: 'УВЕРЕННЫЙ ТЕМП',
      title: '~$perDayStr часа в день',
      subtitle:
          'Заметный прогресс уже через пару недель. Оптимально на финальном году.',
      tone: _Tone.focused,
    );
  }
  if (hours <= 32) {
    return _Hint(
      label: 'ИНТЕНСИВНО',
      title: '~$perDayStr часа в день',
      subtitle:
          'Серьёзная нагрузка. Понадобится дисциплина и нормальный режим сна.',
      tone: _Tone.intense,
    );
  }
  return _Hint(
    label: 'ОЧЕНЬ ИНТЕНСИВНО',
    title: '~$perDayStr часа в день',
    subtitle:
        'Точно уверен? На этом уровне легко выгореть — лучше распределить нагрузку.',
    tone: _Tone.extreme,
  );
}

/// Подсказка про интенсивность. Стилистически — как остальные карточки в
/// приложении: мягкий нейтральный фон, тонкая обводка, скругление 18.
/// Уровень нагрузки показываем компактным «тагом» в верхней строке —
/// именно он несёт цвет, основной текст остаётся в фирменной палитре.
class _HintBox extends StatelessWidget {
  const _HintBox({
    super.key,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final String label;
  final String title;
  final String subtitle;
  final _Tone tone;

  Color _accent() {
    switch (tone) {
      case _Tone.calm:
        return AppColors.secondary;
      case _Tone.normal:
      case _Tone.focused:
        return AppColors.primary;
      case _Tone.intense:
        return AppColors.accent;
      case _Tone.extreme:
        return const Color(0xFFD63B5B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.text.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.text.withValues(alpha: 0.1),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: AppColors.text.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
