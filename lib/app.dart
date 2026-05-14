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
        initialRoute:
            authService.isAuthenticated ? AppRouter.home : AppRouter.welcome,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
