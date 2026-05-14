import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_class_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_hours_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_subjects_page.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';

class AppRouter {
  AppRouter._();

  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const onboardingClass = '/onboarding/class';
  static const onboardingSubjects = '/onboarding/subjects';
  static const onboardingHours = '/onboarding/hours';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _slideRoute(const LoginPage(), settings);
      case register:
        return _slideRoute(const RegisterPage(), settings);
      case forgotPassword:
        return _slideRoute(const ForgotPasswordPage(), settings);
      case home:
        return _slideRoute(const HomePage(), settings);
      case onboardingClass:
        return _slideRoute(const OnboardingClassPage(), settings);
      case onboardingSubjects:
        return _slideRoute(const OnboardingSubjectsPage(), settings);
      case onboardingHours:
        return _slideRoute(const OnboardingHoursPage(), settings);
      case welcome:
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WelcomePage(),
        );
    }
  }

  /// Плавное появление страницы — экран welcome сам отыгрывает свой
  /// «уход» (круг наверх, кнопки вниз), а новая страница просто
  /// проявляется без шаблонного slide-from-right.
  /// Единый стиль перехода для всех экранов (кроме welcome): новая
  /// страница приезжает справа с лёгким fade, предыдущая немного отъезжает
  /// влево и затемняется. Тот же transition отыгрывается в обратную
  /// сторону при свайпе назад, потому что [SwipeBack] двигает контроллер
  /// маршрута, а не саму страницу.
  static PageRoute<T> _slideRoute<T>(Widget page, RouteSettings settings) {
    return SwipeablePageRoute<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      // opaque=false, чтобы при свайпе сквозь сдвинутую страницу было
      // видно ту, что лежит под ней — иначе будет чёрный фон.
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        const reverseCurve = Curves.easeInCubic;

        // Входящая страница: едет справа (или возвращается обратно при pop).
        final enter = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        );
        // Уходящая (нижняя) страница: немного сдвигается влево.
        final exit = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.25, 0),
        ).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        );
        // Затемнение нижней страницы: при полном переходе насыщается до 35%.
        final dim = Tween<double>(begin: 0, end: 0.35).animate(
          CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: exit,
          child: AnimatedBuilder(
            animation: dim,
            builder: (context, dimChild) {
              return ColoredBox(
                color: Colors.black.withValues(alpha: dim.value),
                child: dimChild,
              );
            },
            child: SlideTransition(
              position: enter,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.15, 1, curve: Curves.easeOut),
                  reverseCurve: Curves.easeIn,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Наследник [PageRouteBuilder], который предоставляет доступ к
/// внутреннему `controller` снаружи (он у `TransitionRoute` `protected`).
/// Используется в [SwipeBack], чтобы свайп напрямую двигал значение
/// контроллера маршрута и сам route отрисовывал переход обеих страниц.
class SwipeablePageRoute<T> extends PageRouteBuilder<T> {
  SwipeablePageRoute({
    required super.pageBuilder,
    super.settings,
    super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.opaque,
  });

  AnimationController get swipeController => controller!;
}
