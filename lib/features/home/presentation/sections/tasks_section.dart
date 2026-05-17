import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../auth/data/auth_service.dart';
import '../../../onboarding/data/ege_subjects.dart';
import '../../../onboarding/data/mock_exam_bank.dart';
import '../../../onboarding/presentation/pages/mock_exam_take_page.dart';
import '../widgets/section_header.dart';

/// Главный раздел: реальные задачи формата ЕГЭ + список предметов.
///
/// Источники данных:
/// - `user.subjects` — выбранные предметы.
/// - `mockExamBankBySubject` — реальный банк задач в формате ЕГЭ
///   (см. `lib/features/onboarding/data/mock_exam_bank.dart`).
///
/// «На сегодня» — 3 задачи, выбранные детерминированно по дню недели
/// из объединённого пула задач выбранных предметов. «Все предметы» —
/// список предметов с количеством задач в банке.
class TasksSection extends StatelessWidget {
  const TasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final selected = egeSubjects
        .where((s) => user?.subjects.contains(s.id) ?? false)
        .toList(growable: false);
    final weeklyHours = user?.weeklyHours ?? 0;

    // Пул реальных задач — конкатенация банков по выбранным предметам.
    // Каждая задача снабжена ссылкой на предмет, чтобы показать иконку.
    final pool = <_TaskWithSubject>[];
    for (final s in selected) {
      final bank = mockExamBankBySubject[s.id] ?? const <MockExamTask>[];
      for (final t in bank) {
        pool.add(_TaskWithSubject(subject: s, task: t));
      }
    }
    final today = _todayTasks(pool);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        const SizedBox(height: 8),
        SectionHeader(
          title: 'Привет, ${user?.name ?? ''}!',
          subtitle: selected.isEmpty
              ? 'Выбери предметы в онбординге, чтобы построить план.'
              : weeklyHours > 0
                  ? 'У тебя ${selected.length} предметов · '
                      '$weeklyHours ч в неделю.'
                  : 'У тебя ${selected.length} предметов.',
        ),
        const SizedBox(height: 20),
        const _WeekStrip(),
        const SizedBox(height: 20),
        if (selected.isEmpty)
          TileCard(
            child: Text(
              'Ты ещё не выбрал предметы. Зайди в онбординг, чтобы '
              'настроить план подготовки.',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.text.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
          )
        else ...[
          _GroupLabel('На сегодня', counter: today.length),
          const SizedBox(height: 10),
          for (final entry in today) ...[
            _RealTaskCard(entry: entry),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          _GroupLabel('Все предметы', counter: selected.length),
          const SizedBox(height: 10),
          for (final s in selected) ...[
            _SubjectTaskCard(
              subject: s,
              tasksInBank: (mockExamBankBySubject[s.id] ?? const []).length,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  /// Детерминированный срез на сегодня: 3 задачи из пула, сдвиг по weekday.
  List<_TaskWithSubject> _todayTasks(List<_TaskWithSubject> pool) {
    if (pool.isEmpty) return const [];
    final take = pool.length < 3 ? pool.length : 3;
    final offset = (DateTime.now().weekday - 1) % pool.length;
    return [for (var i = 0; i < take; i++) pool[(offset + i) % pool.length]];
  }
}

class _TaskWithSubject {
  const _TaskWithSubject({required this.subject, required this.task});

  final EgeSubject subject;
  final MockExamTask task;
}

/// Лента активности — одна неделя в стиле GitHub: 7 квадратов (Пн–Вс).
/// Реальных данных пока нет → все дни показываются как «0 активности».
/// Сегодняшний день обводится primary-бордером.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  static const _labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday - 1; // 0..6
    final emptyColor = AppColors.text.withValues(alpha: 0.06);

    return TileCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Эта неделя',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Text(
                '0 из 7 дней',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 8.0;
              final cell = (c.maxWidth - gap * 6) / 7;
              return Row(
                children: [
                  for (var d = 0; d < 7; d++) ...[
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: cell,
                            height: cell,
                            decoration: BoxDecoration(
                              color: emptyColor,
                              borderRadius: BorderRadius.circular(8),
                              border: d == today
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _labels[d],
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 11,
                              fontWeight: d == today
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: d == today
                                  ? AppColors.primary
                                  : AppColors.text.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (d != 6) const SizedBox(width: gap),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.title, {required this.counter});

  final String title;
  final int counter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$counter',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка реальной задачи из банка ЕГЭ: иконка предмета, источник
/// (например «Формат ЕГЭ: орфоэпия»), и сам текст задачи. Тап открывает
/// тренажёр по предмету — пользователь сразу попадает в режим решения.
class _RealTaskCard extends StatelessWidget {
  const _RealTaskCard({required this.entry});

  final _TaskWithSubject entry;

  void _openSolve(BuildContext context) {
    final score = context.read<AuthService>().currentUser
        ?.mockExamScores[entry.subject.id];
    Navigator.of(context).pushNamed(
      AppRouter.mockExamTake,
      arguments: MockExamTakeArgs(
        subjectId: entry.subject.id,
        subjectTitle: entry.subject.title,
        initialScore: score ?? 0,
        isPractice: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TileCard(
      onTap: () => _openSolve(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(entry.subject.iconAsset, width: 28, height: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subject.title,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.task.prompt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.task.source,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.text.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка предмета с числом задач в реальном банке ЕГЭ. Тап
/// открывает тренажёр для решения всех задач этого предмета.
class _SubjectTaskCard extends StatelessWidget {
  const _SubjectTaskCard({
    required this.subject,
    required this.tasksInBank,
  });

  final EgeSubject subject;
  final int tasksInBank;

  String _taskWord(int n) {
    final m10 = n % 10;
    final m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'задача';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'задачи';
    return 'задач';
  }

  void _openSolve(BuildContext context) {
    final score = context.read<AuthService>().currentUser
        ?.mockExamScores[subject.id];
    Navigator.of(context).pushNamed(
      AppRouter.mockExamTake,
      arguments: MockExamTakeArgs(
        subjectId: subject.id,
        subjectTitle: subject.title,
        initialScore: score ?? 0,
        isPractice: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TileCard(
      onTap: tasksInBank == 0 ? null : () => _openSolve(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(subject.iconAsset, width: 28, height: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.title,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tasksInBank == 0
                      ? 'Задачи появятся позже'
                      : '$tasksInBank ${_taskWord(tasksInBank)} · формат ЕГЭ',
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
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.text.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}
