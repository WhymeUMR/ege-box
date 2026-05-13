import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';

class AppRouter {
  AppRouter._();

  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _fadeRoute(const LoginPage(), settings);
      case register:
        return _fadeRoute(const RegisterPage(), settings);
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
  static PageRoute<T> _fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}
