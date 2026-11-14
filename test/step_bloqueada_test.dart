import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_app/models/onboarding.dart';
import 'package:onboarding_app/screens/empleado/widgets/step_card.dart';
import 'package:onboarding_app/screens/empleado/widgets/task_row.dart';

StepConProgreso _step({required bool bloqueada}) => StepConProgreso.fromJson({
      'id_step': 2,
      'titulo': 'Etapa 2',
      'orden': 2,
      'total_tasks': 1,
      'completadas': 0,
      'bloqueada': bloqueada,
      'bloqueada_por': bloqueada ? 'Etapa 1' : null,
      'tasks': [
        {
          'id_task_progress': 1,
          'id_task': 10,
          'id_step': 2,
          'estado': 'PENDIENTE',
          'titulo': 'Tarea B1',
          'tipo': 'CONFIRMACION',
          'obligatorio': true,
          'orden': 1,
        }
      ],
    });

Future<int> _montar(WidgetTester t, StepConProgreso step) async {
  var toggles = 0;
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: StepCard(
          step: step,
          numero: 2,
          idOnboarding: 1,
          expandido: true, // aunque se pida expandido, bloqueada no debe abrir
          onToggle: () => toggles++,
          onCompletarTask: (_) async {},
        ),
      ),
    ),
  ));
  return toggles;
}

void main() {
  testWidgets('etapa bloqueada: candado, motivo y sin tareas', (t) async {
    await _montar(t, _step(bloqueada: true));
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.textContaining('Completa «Etapa 1» para desbloquear'),
        findsOneWidget);
    expect(find.byType(TaskRow), findsNothing);
    expect(find.text('Tarea B1'), findsNothing);
  });

  testWidgets('etapa desbloqueada: muestra sus tareas', (t) async {
    await _montar(t, _step(bloqueada: false));
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.byType(TaskRow), findsOneWidget);
    expect(find.text('Tarea B1'), findsOneWidget);
  });
}
