import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/app/corretor_app.dart';

void main() {
  testWidgets('renderiza tela de autenticacao', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CorretorApp());
    await tester.pumpAndSettle();

    expect(find.text('Corretor de Imoveis'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
  });
}
