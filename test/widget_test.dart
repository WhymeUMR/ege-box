import 'package:ege_box/app.dart';
import 'package:ege_box/core/constants/app_strings.dart';
import 'package:ege_box/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Размер тестового экрана близкий к реальному телефону.
const _phoneSize = Size(390, 844);

/// Mock AuthService для тестов.
class _MockAuthService extends ChangeNotifier implements AuthService {
  @override
  bool get isAuthenticated => false;

  @override
  AuthUser? get currentUser => null;

  @override
  String? get token => null;

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordRepeat,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  bool get isOnboarded => false;

  @override
  Future<void> setGrade(int grade) async {}

  @override
  Future<void> setSubjects(List<String> subjects) async {}

  @override
  Future<void> setWeeklyHours(int hours) async {}
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_phoneSize);
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Welcome screen shows typewriter tagline and auth buttons', (
    tester,
  ) async {
    await _setPhoneSurface(tester);
    final authService = _MockAuthService();
    await tester.pumpWidget(EgeBoxApp(authService: authService));
    // Дать анимациям выезда отыграть, плюс часть фразы напечататься.
    await tester.pump(const Duration(seconds: 2));

    final firstPhrase = AppStrings.welcomeTaglines.first;
    final prefix = firstPhrase.substring(0, 6);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains(prefix),
      ),
      findsWidgets,
    );
    expect(find.text(AppStrings.signIn), findsOneWidget);
    expect(find.text(AppStrings.signUp), findsOneWidget);
  });

  testWidgets('Tap "Войти" navigates to login', (tester) async {
    await _setPhoneSurface(tester);
    final authService = _MockAuthService();
    await tester.pumpWidget(EgeBoxApp(authService: authService));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.signIn));
    // Прокачиваем кадры, пока welcome отыгрывает «уход» и грузится login.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // На login-экране есть поле "Почта" и заголовок-приветствие.
    expect(find.text(AppStrings.loginTitle), findsOneWidget);
    expect(find.text(AppStrings.emailHint), findsOneWidget);
  });
}
