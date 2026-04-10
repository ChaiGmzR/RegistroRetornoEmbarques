// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:registro_retorno_embarques/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const RegistroEmbarquesApp(enableStartupUpdateCheck: false),
    );

    expect(find.text('Registro Retorno Embarques'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
