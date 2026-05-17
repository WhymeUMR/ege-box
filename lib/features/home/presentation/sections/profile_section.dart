import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../auth/data/auth_service.dart';
import '../widgets/section_header.dart';

/// Личный кабинет: инфо о пользователе, настройки, выход.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.welcome,
      (_) => false,
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.characters.firstOrNull ?? '';
    final last = parts.length > 1
        ? (parts.last.characters.firstOrNull ?? '')
        : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        const SizedBox(height: 8),
        const SectionHeader(
          title: 'Личный кабинет',
          subtitle: 'Настройки подготовки и аккаунта.',
        ),
        const SizedBox(height: 20),
        _ProfileHero(
          name: user?.name ?? '',
          email: user?.email ?? '',
          initials: _initials(user?.name),
        ),
        const SizedBox(height: 12),
        Consumer<ActivityService>(
          builder: (context, a, _) => _StreakPill(days: a.currentStreak()),
        ),
        const SizedBox(height: 16),
        _MenuRow(
          icon: Icons.school_outlined,
          title: 'Класс',
          trailing: user?.grade == null ? '—' : '${user!.grade} класс',
        ),
        const SizedBox(height: 10),
        _MenuRow(
          icon: Icons.timer_outlined,
          title: 'Часов в неделю',
          trailing: user?.weeklyHours == null ? '—' : '${user!.weeklyHours} ч',
        ),
        const SizedBox(height: 10),
        _MenuRow(
          icon: Icons.menu_book_outlined,
          title: 'Предметы',
          trailing: '${user?.subjects.length ?? 0}',
        ),
        const SizedBox(height: 10),
        const _MenuRow(
          icon: Icons.help_outline_rounded,
          title: 'Помощь и поддержка',
        ),
        const SizedBox(height: 10),
        const _MenuRow(icon: Icons.info_outline_rounded, title: 'О приложении'),
        const SizedBox(height: 24),
        PillPrimaryButton(label: 'Выйти', onPressed: () => _logout(context)),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.initials,
  });

  final String name;
  final String email;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Профиль' : name,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.background.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  String _suffix(int n) {
    final m10 = n % 10;
    final m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'день';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'дня';
    return 'дней';
  }

  @override
  Widget build(BuildContext context) {
    final isZero = days == 0;
    final accent = isZero
        ? AppColors.text.withValues(alpha: 0.45)
        : AppColors.primary;
    return TileCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isZero
                  ? AppColors.text.withValues(alpha: 0.06)
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Серия дней подряд',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isZero
                      ? 'Начни сегодня — и появится стрик'
                      : 'Продолжай в том же духе',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$days',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' ${_suffix(days)}',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return TileCard(
      onTap: () {},
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.text, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          if (trailing != null) ...[
            Text(
              trailing!,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.text.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}
