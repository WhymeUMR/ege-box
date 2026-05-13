import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/providers/home_provider.dart';

class EgeBoxApp extends StatelessWidget {
  const EgeBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
