import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../../onboarding/data/ege_subjects.dart';
import '../widgets/section_header.dart';

/// Раздел материалов: теория, конспекты, шпаргалки по предметам.
class MaterialsSection extends StatelessWidget {
  const MaterialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final selected = egeSubjects
        .where((s) => user?.subjects.contains(s.id) ?? false)
        .toList(growable: false);
    final list = selected.isEmpty ? egeSubjects : selected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        const SizedBox(height: 8),
        const SectionHeader(
          title: 'Материалы',
          subtitle: 'Конспекты, теория и шпаргалки по каждому предмету.',
        ),
        const SizedBox(height: 20),
        for (final s in list) ...[
          _MaterialSubjectTile(title: s.title, iconAsset: s.iconAsset),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MaterialSubjectTile extends StatelessWidget {
  const _MaterialSubjectTile({required this.title, required this.iconAsset});

  final String title;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return TileCard(
      onTap: () {},
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
                const SizedBox(height: 2),
                Text(
                  'Теория · конспекты · формулы',
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
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.text.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}
