import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/ege_subjects.dart';
import 'mock_exam_take_page.dart';

class OnboardingMockExamPage extends StatefulWidget {
  const OnboardingMockExamPage({super.key});

  @override
  State<OnboardingMockExamPage> createState() => _OnboardingMockExamPageState();
}

class _OnboardingMockExamPageState extends State<OnboardingMockExamPage> {
  String? _selectedSubjectId;

  List<EgeSubject> get _selectedSubjects {
    final selectedIds =
        context.read<AuthService>().currentUser?.subjects ?? const <String>[];
    return egeSubjects
        .where((subject) => selectedIds.contains(subject.id))
        .toList(growable: false);
  }

  Future<void> _onStartMockExam(List<EgeSubject> subjects) async {
    final selectedId = _selectedSubjectId;
    if (selectedId == null) return;
    final subject = subjects.firstWhere((s) => s.id == selectedId);
    final score =
        (context.read<AuthService>().currentUser?.mockExamScores[selectedId]) ??
        0;
    await _onOpenMockExam(subject, score);
  }

  void _onSkip() {
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
  }

  Future<void> _onOpenMockExam(EgeSubject subject, int currentScore) async {
    final nextScore = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => MockExamTakePage(
          subjectTitle: subject.title,
          initialScore: currentScore,
        ),
      ),
    );
    if (!mounted || nextScore == null) return;
    await context.read<AuthService>().setMockExamScore(
      subjectId: subject.id,
      score: nextScore,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final name = user?.name ?? 'Друг';
    final scores = user?.mockExamScores ?? const <String, int>{};
    final subjects = _selectedSubjects;

    return SwipeBack(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.onboardingMockTitle,
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
                  AppStrings.onboardingMockBody(name),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text.withValues(alpha: 0.64),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.onboardingMockHint,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text.withValues(alpha: 0.64),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  AppStrings.onboardingMockChoose,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: subjects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final score = scores[subject.id] ?? 0;
                      return _SubjectChoiceButton(
                        title: subject.title,
                        score: score,
                        selected: _selectedSubjectId == subject.id,
                        onTap: () {
                          setState(() {
                            _selectedSubjectId = subject.id;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                PillPrimaryButton(
                  label: AppStrings.onboardingMockStart,
                  onPressed: _selectedSubjectId == null
                      ? null
                      : () => _onStartMockExam(subjects),
                ),
                const SizedBox(height: 10),
                PillOutlinedButton(
                  label: AppStrings.onboardingMockSkip,
                  onPressed: _onSkip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectChoiceButton extends StatelessWidget {
  const _SubjectChoiceButton({
    required this.title,
    required this.score,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int score;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.text.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.text.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      height: 1.15,
                    ),
                  ),
                ),
                Text(
                  '$score/100',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(score),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.background,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.text.withValues(alpha: 0.25),
                      width: 1.4,
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.text,
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

Color _scoreColor(int score) {
  if (score >= 80) return const Color(0xFF138A36);
  if (score >= 60) return const Color(0xFF2E9D6A);
  if (score >= 40) return const Color(0xFFC68A00);
  if (score >= 20) return const Color(0xFFB05A00);
  return AppColors.text.withValues(alpha: 0.65);
}
