import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/activity_service.dart';
import 'core/services/topic_stats_service.dart';
import 'features/auth/data/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Только вертикальная ориентация — landscape-вёрстку мы не делаем.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final authService = await AuthService.create();
  final activityService = await ActivityService.create();
  final topicStatsService = await TopicStatsService.create();
  runApp(
    EgeBoxApp(
      authService: authService,
      activityService: activityService,
      topicStatsService: topicStatsService,
    ),
  );
}
