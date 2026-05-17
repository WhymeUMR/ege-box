import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../auth/data/auth_service.dart';
import '../../../onboarding/data/ege_subjects.dart';
import '../../../onboarding/data/mock_exam_bank.dart';
import '../../../onboarding/presentation/pages/mock_exam_take_page.dart';
import '../widgets/section_header.dart';

/// Раздел пробников ЕГЭ: запуск и просмотр результатов.
class MocksSection extends StatelessWidget {
  const MocksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final scores = user?.mockExamScores ?? const <String, int>{};
    final selected = egeSubjects
        .where((s) => user?.subjects.contains(s.id) ?? false)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        const SizedBox(height: 8),
        const SectionHeader(
          title: 'Пробники',
          subtitle: 'Полные варианты ЕГЭ — оцени уровень и следи за прогрессом.',
        ),
        const SizedBox(height: 20),
        for (final s in selected) ...[
          _MockCard(
            subjectId: s.id,
            title: s.title,
            iconAsset: s.iconAsset,
            score: scores[s.id],
            tasksInBank: (mockExamBankBySubject[s.id] ?? const []).length,
          ),
          const SizedBox(height: 12),
        ],
        if (selected.isEmpty)
          TileCard(
            child: Text(
              'Сначала выбери предметы в онбординге, чтобы запускать пробники.',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.text.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard({
    required this.subjectId,
    required this.title,
    required this.iconAsset,
    required this.score,
    required this.tasksInBank,
  });

  final String subjectId;
  final String title;
  final String iconAsset;
  final int? score;
  final int tasksInBank;

  String _taskWord(int n) {
    final m10 = n % 10;
    final m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'задача';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'задачи';
    return 'задач';
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    return TileCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.mockExamTake,
          arguments: MockExamTakeArgs(
            subjectId: subjectId,
            subjectTitle: title,
            initialScore: score ?? 0,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Image.asset(iconAsset, width: 28, height: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasScore
                          ? '$tasksInBank ${_taskWord(tasksInBank)} · '
                              'результат $score / 100'
                          : '$tasksInBank ${_taskWord(tasksInBank)} · '
                              'ещё не пройден',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _StartBadge(label: hasScore ? 'Ещё раз' : 'Начать'),
            ],
          ),
          if (hasScore) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (score! / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.text.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StartBadge extends StatelessWidget {
  const _StartBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.background,
        ),
      ),
    );
  }
}
