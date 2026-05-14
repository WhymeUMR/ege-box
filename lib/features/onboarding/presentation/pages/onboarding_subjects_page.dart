import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/ege_subjects.dart';
import '../widgets/step_progress.dart';
import '../widgets/subject_chip.dart';

/// Шаг 2 онбординга: выбор предметов ЕГЭ (3–5 из 12).
class OnboardingSubjectsPage extends StatefulWidget {
  const OnboardingSubjectsPage({super.key});

  @override
  State<OnboardingSubjectsPage> createState() => _OnboardingSubjectsPageState();
}

class _OnboardingSubjectsPageState extends State<OnboardingSubjectsPage> {
  final Set<String> _selected = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Если пользователь возвращается на шаг — подтянем уже сохранённый выбор.
    final existing =
        context.read<AuthService>().currentUser?.subjects ?? const [];
    _selected.addAll(existing);
  }

  /// Профильная и базовая математика взаимоисключают друг друга — при
  /// выборе одной автоматически снимаем другую.
  static const _mathExclusive = {
    'math_prof': 'math_base',
    'math_base': 'math_prof',
  };

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < egeSubjectsMax ||
          (_mathExclusive[id] != null &&
              _selected.contains(_mathExclusive[id]))) {
        // Если выбираем альтернативную математику — сначала убираем
        // противоположную, чтобы не упереться в лимит и не держать обе.
        final opposite = _mathExclusive[id];
        if (opposite != null) _selected.remove(opposite);
        _selected.add(id);
      } else {
        // Достигнут максимум — мягко подсказываем.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Можно выбрать не больше $egeSubjectsMax предметов',
              ),
              duration: const Duration(milliseconds: 1400),
            ),
          );
      }
    });
  }

  bool get _canProceed =>
      _selected.length >= egeSubjectsMin &&
      _selected.length <= egeSubjectsMax &&
      !_busy;

  Future<void> _onNext() async {
    if (!_canProceed) return;
    setState(() => _busy = true);
    try {
      // Сохраняем в порядке списка предметов, чтобы было детерминировано.
      final ordered = egeSubjects
          .where((s) => _selected.contains(s.id))
          .map((s) => s.id)
          .toList(growable: false);
      await context.read<AuthService>().setSubjects(ordered);
      if (!mounted) return;
      // push (а не replace), чтобы со 3-го шага свайп вёл на 2-й.
      Navigator.of(context).pushNamed(AppRouter.onboardingHours);
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
    final atMax = _selected.length >= egeSubjectsMax;

    return SwipeBack(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepProgress(
                  label: AppStrings.onboardingStepSubjects,
                  current: 2,
                  total: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  AppStrings.onboardingSubjectsTitle,
                  style: TextStyle(
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
                  AppStrings.onboardingSubjectsSubtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: egeSubjects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = egeSubjects[i];
                      return SubjectChip(
                        title: s.title,
                        iconAsset: s.iconAsset,
                        selected: _selected.contains(s.id),
                        disabled: atMax,
                        onTap: () => _toggle(s.id),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Text(
                    AppStrings.onboardingSubjectsCounter(
                      _selected.length,
                      egeSubjectsMin,
                      egeSubjectsMax,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _canProceed
                          ? AppColors.primary
                          : AppColors.text.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                PillPrimaryButton(
                  label: AppStrings.onboardingNext,
                  onPressed: _canProceed ? _onNext : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
