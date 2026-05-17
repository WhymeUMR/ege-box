import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../sections/materials_section.dart';
import '../sections/mocks_section.dart';
import '../sections/profile_section.dart';
import '../sections/stats_section.dart';
import '../sections/tasks_section.dart';
import '../widgets/main_nav_bar.dart';

/// Главный экран приложения с пятью разделами и стеклянным навбаром.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MainNavItem _current = MainNavItem.tasks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: MainNavItem.values.indexOf(_current),
                children: const [
                  TasksSection(),
                  StatsSection(),
                  MaterialsSection(),
                  MocksSection(),
                  ProfileSection(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 4,
            child: Center(
              child: MainNavBar(
                selectedItem: _current,
                onSelected: (item) => setState(() => _current = item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
