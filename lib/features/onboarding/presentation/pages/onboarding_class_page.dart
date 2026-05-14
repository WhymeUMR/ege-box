import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../../../auth/data/auth_service.dart';
import '../widgets/grade_card.dart';
import '../widgets/step_progress.dart';

/// Шаг 1 онбординга: выбор класса (9/10/11).
class OnboardingClassPage extends StatefulWidget {
  const OnboardingClassPage({super.key});

  @override
  State<OnboardingClassPage> createState() => _OnboardingClassPageState();
}

class _OnboardingClassPageState extends State<OnboardingClassPage> {
  int? _grade;
  bool _busy = false;

  Future<void> _onNext() async {
    final grade = _grade;
    if (grade == null || _busy) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().setGrade(grade);
      if (!mounted) return;
      // push (а не replace), чтобы на шаге 2 работал свайп назад на шаг 1.
      Navigator.of(context).pushNamed(AppRouter.onboardingSubjects);
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

    // SwipeBack — для консистентности с остальными экранами. На первом
    // шаге онбординга стек пуст, поэтому жест просто ничего не делает.
    return SwipeBack(
      child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgress(
                label: AppStrings.onboardingStepClass,
                current: 1,
                total: 3,
              ),
              const SizedBox(height: 28),
              Text(
                AppStrings.onboardingClassTitle(name),
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.onboardingClassSubtitle,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: AppColors.text.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              for (final g in const [9, 10, 11]) ...[
                GradeCard(
                  grade: g,
                  selected: _grade == g,
                  onTap: () => setState(() => _grade = g),
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(),
              PillPrimaryButton(
                label: AppStrings.onboardingNext,
                onPressed: _grade == null || _busy ? null : _onNext,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
