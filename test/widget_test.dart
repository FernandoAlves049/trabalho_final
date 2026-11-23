import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabalho_final/ui/auth_screens.dart';

void main() {
  testWidgets('Cadastro exige nome, e-mail válido e senhas iguais', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'exemplo');
    await tester.enterText(fields.at(2), 'senha123');
    await tester.enterText(fields.at(3), 'outra');
    await tester.scrollUntilVisible(
      find.text('Cadastrar'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('As senhas devem ser iguais.'), findsOneWidget);
  });
}
