import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';

class EgeBoxApp extends StatelessWidget {
  const EgeBoxApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: AppTheme.theme,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: _initialStack(authService).last,
        onGenerateInitialRoutes: (initialRoute) {
          // Возвращаем сразу несколько маршрутов в стеке, чтобы свайп
          // назад с любого шага онбординга вёл на предыдущий, а не на
          // главный (или welcome).
          return [
            for (final name in _initialStack(authService))
              AppRouter.onGenerateRoute(RouteSettings(name: name)),
          ];
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Стек маршрутов для холодного старта приложения. Последний элемент —
  /// тот экран, который пользователь увидит; остальные лежат под ним и
  /// открываются жестом «назад».
  static List<String> _initialStack(AuthService auth) {
    if (!auth.isAuthenticated) return [AppRouter.welcome];
    final user = auth.currentUser!;
    if (user.grade == null) {
      return [AppRouter.onboardingClass];
    }
    if (user.subjects.isEmpty) {
      return [AppRouter.onboardingClass, AppRouter.onboardingSubjects];
    }
    return [AppRouter.home];
  }
}
