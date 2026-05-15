import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';
import 'features/onboarding/presentation/pages/mock_exam_take_page.dart';

class EgeBoxApp extends StatefulWidget {
  const EgeBoxApp({super.key, required this.authService});

  final AuthService authService;

  @override
  State<EgeBoxApp> createState() => _EgeBoxAppState();
}

class _EgeBoxAppState extends State<EgeBoxApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.authService.flushProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>.value(
      value: widget.authService,
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: AppTheme.theme,
        onGenerateRoute: AppRouter.onGenerateRoute,
        navigatorObservers: [_RouteProgressObserver(widget.authService)],
        initialRoute: _initialStack(widget.authService).last.name,
        onGenerateInitialRoutes: (initialRoute) {
          // Возвращаем сразу несколько маршрутов в стеке, чтобы свайп
          // назад с любого шага онбординга вёл на предыдущий, а не на
          // главный (или welcome).
          return [
            for (final settings in _initialStack(widget.authService))
              AppRouter.onGenerateRoute(settings),
          ];
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Стек маршрутов для холодного старта приложения. Последний элемент —
  /// тот экран, который пользователь увидит; остальные лежат под ним и
  /// открываются жестом «назад».
  static List<RouteSettings> _initialStack(AuthService auth) {
    if (!auth.isAuthenticated) {
      return const [RouteSettings(name: AppRouter.welcome)];
    }
    final user = auth.currentUser!;
    if (user.grade == null) {
      return const [RouteSettings(name: AppRouter.onboardingClass)];
    }
    if (user.subjects.isEmpty) {
      return const [
        RouteSettings(name: AppRouter.onboardingClass),
        RouteSettings(name: AppRouter.onboardingSubjects),
      ];
    }
    if (user.weeklyHours == null) {
      return const [
        RouteSettings(name: AppRouter.onboardingClass),
        RouteSettings(name: AppRouter.onboardingSubjects),
        RouteSettings(name: AppRouter.onboardingHours),
      ];
    }
    final lastRoute = auth.lastRoute;
    if (lastRoute == AppRouter.onboardingMock) {
      return const [RouteSettings(name: AppRouter.onboardingMock)];
    }
    final draft = auth.mockExamDraft;
    if (lastRoute == AppRouter.mockExamTake && draft != null) {
      return [
        const RouteSettings(name: AppRouter.onboardingMock),
        RouteSettings(
          name: AppRouter.mockExamTake,
          arguments: MockExamTakeArgs(
            subjectId: draft.subjectId,
            subjectTitle: draft.subjectTitle,
            initialScore: user.mockExamScores[draft.subjectId] ?? 0,
          ),
        ),
      ];
    }
    if (lastRoute == AppRouter.mockExamTake) {
      return const [RouteSettings(name: AppRouter.onboardingMock)];
    }
    return const [RouteSettings(name: AppRouter.home)];
  }
}

class _RouteProgressObserver extends NavigatorObserver {
  _RouteProgressObserver(this.auth);

  final AuthService auth;

  static const _tracked = {
    AppRouter.onboardingClass,
    AppRouter.onboardingSubjects,
    AppRouter.onboardingHours,
    AppRouter.onboardingMock,
    AppRouter.mockExamTake,
    AppRouter.home,
  };

  void _save(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || !_tracked.contains(name)) return;
    auth.setLastRoute(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _save(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _save(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _save(newRoute);
  }
}
