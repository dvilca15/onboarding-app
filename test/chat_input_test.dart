import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_app/widgets/chat_ui.dart';

void main() {
  Future<(TextEditingController, List<int>)> montar(
      WidgetTester tester, {bool cargando = false}) async {
    final ctrl = TextEditingController();
    final enviados = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChatInput(
            controller: ctrl,
            cargando: cargando,
            hint: 'Escribe...',
            onSend: () => enviados.add(1),
          ),
        ),
      ),
    ));
    return (ctrl, enviados);
  }

  testWidgets('Enter envía el mensaje', (tester) async {
    final (ctrl, enviados) = await montar(tester);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hola');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(enviados.length, 1);
    expect(ctrl.text, 'hola'); // no se insertó salto de línea
  });

  testWidgets('Shift+Enter NO envía', (tester) async {
    final (_, enviados) = await montar(tester);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hola');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(enviados, isEmpty);
  });

  testWidgets('el botón envía solo si hay texto', (tester) async {
    final (ctrl, enviados) = await montar(tester);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(enviados, isEmpty); // vacío: no envía

    ctrl.text = 'hola';
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(enviados.length, 1);
  });

  testWidgets('mientras carga, el botón no envía y muestra spinner',
      (tester) async {
    final (ctrl, enviados) = await montar(tester, cargando: true);
    ctrl.text = 'hola';
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(InkWell).last);
    await tester.pump();
    expect(enviados, isEmpty);
  });
}
