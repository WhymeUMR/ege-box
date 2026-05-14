import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/data/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = await AuthService.create();
  runApp(EgeBoxApp(authService: authService));
}
