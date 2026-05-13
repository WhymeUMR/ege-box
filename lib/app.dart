import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class EgeBoxApp extends StatelessWidget {
  const EgeBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.theme,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.welcome,
      debugShowCheckedModeBanner: false,
    );
  }
}
