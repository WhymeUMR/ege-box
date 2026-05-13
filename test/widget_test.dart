import 'package:ege_box/app.dart';
import 'package:ege_box/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Размер тестового экрана близкий к реальному телефону.
const _phoneSize = Size(390, 844);

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
  testWidgets('Welcome screen shows typewriter tagline and auth buttons',
      (tester) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(const EgeBoxApp());
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
    await tester.pumpWidget(const EgeBoxApp());
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.signIn));
    // Прокачиваем кадры, пока идёт переход маршрутизации.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(AppBar), findsOneWidget);
  });
}
