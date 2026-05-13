import 'package:ege_box/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home page increments counter', (tester) async {
    await tester.pumpWidget(const EgeBoxApp());

    expect(find.text('Tapped 0 times'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Tapped 1 times'), findsOneWidget);
  });
}
