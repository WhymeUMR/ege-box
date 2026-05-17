import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/topic_stats_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../../onboarding/data/ege_subjects.dart';
import '../widgets/section_header.dart';

/// Раздел статистики: средний балл, метрики и прогресс по предметам.
class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final scores = user?.mockExamScores ?? const <String, int>{};
    final selected = egeSubjects
        .where((s) => user?.subjects.contains(s.id) ?? false)
        .toList(growable: false);

    final values = scores.values.toList();
    final avg = values.isEmpty
        ? 0
        : (values.reduce((a, b) => a + b) / values.length).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        const SizedBox(height: 8),
        const SectionHeader(
          title: 'Статистика',
          subtitle: 'Как ты идёшь к ЕГЭ — в одном месте.',
        ),
        const SizedBox(height: 20),
        _AverageHero(score: avg, hasData: values.isNotEmpty),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Пробников',
                value: '${scores.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Предметов',
                value: '${selected.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Часов в неделю',
                value: user?.weeklyHours == null
                    ? '—'
                    : '${user!.weeklyHours}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Класс',
                value: user?.grade == null ? '—' : '${user!.grade}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _WeakTopicsBlock(),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'По предметам',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text.withValues(alpha: 0.85),
            ),
          ),
        ),
        for (final s in selected) ...[
          _SubjectProgressTile(
            title: s.title,
            iconAsset: s.iconAsset,
            score: scores[s.id],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AverageHero extends StatelessWidget {
  const _AverageHero({required this.score, required this.hasData});

  final int score;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Средний балл',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.background.withValues(alpha: 0.85),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasData ? '$score' : '—',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: AppColors.background,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.background.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasData
                ? 'По итогам пройденных пробников'
                : 'Пройди первый пробник, чтобы увидеть средний балл',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.background.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TileCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectProgressTile extends StatelessWidget {
  const _SubjectProgressTile({
    required this.title,
    required this.iconAsset,
    required this.score,
  });

  final String title;
  final String iconAsset;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final value = (score ?? 0) / 100;
    return TileCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(iconAsset, width: 26, height: 26),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: AppColors.text.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            score == null ? '—' : '$score',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: score == null
                  ? AppColors.text.withValues(alpha: 0.45)
                  : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Блок «Слабые темы» — топ-3 тем с максимальной долей ошибок,
/// агрегированные `TopicStatsService` по реальным попыткам.
class _WeakTopicsBlock extends StatelessWidget {
  const _WeakTopicsBlock();

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TopicStatsService>();
    final weak = stats.weakest();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Слабые темы',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text.withValues(alpha: 0.85),
            ),
          ),
        ),
        if (weak.isEmpty)
          TileCard(
            child: Text(
              'Реши пробник или несколько задач — и AI покажет, где у тебя '
              'больше всего ошибок.',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
          )
        else
          for (final s in weak) ...[
            _WeakTopicTile(stats: s),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _WeakTopicTile extends StatelessWidget {
  const _WeakTopicTile({required this.stats});

  final TopicStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.errorRate * 100).round();
    return TileCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.topic,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.errors} из ${stats.attempts} попыток с ошибкой',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$pct%',
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
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
