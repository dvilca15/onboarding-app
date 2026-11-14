import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_app/theme/app_theme.dart';
import 'package:onboarding_app/theme/app_toast.dart';

Future<BuildContext> _montar(WidgetTester t) async {
  late BuildContext ctx;
  await t.pumpWidget(MaterialApp(
    navigatorKey: AppToast.navigatorKey,
    theme: AppTheme.light,
    home: Scaffold(body: Builder(builder: (c) {
      ctx = c;
      return const SizedBox.expand();
    })),
  ));
  return ctx;
}

void main() {
  testWidgets('muestra el toast y se cierra solo', (t) async {
    final ctx = await _montar(t);
    AppToast.success(ctx, 'Tarea completada');
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Tarea completada'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await t.pump(const Duration(seconds: 4)); // pasa la duración
    await t.pump(const Duration(milliseconds: 400)); // animación de salida
    expect(find.text('Tarea completada'), findsNothing);
  });

  testWidgets('es compacto: no ocupa todo el ancho', (t) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final ctx = await _montar(t);
    AppToast.error(ctx, 'No se pudo guardar');
    await t.pump(const Duration(milliseconds: 300));
    final ancho = t.getSize(find.byType(Material).last).width;
    expect(ancho, lessThanOrEqualTo(380));
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    await t.pump(const Duration(seconds: 7));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('un toast nuevo reemplaza al anterior', (t) async {
    final ctx = await _montar(t);
    AppToast.info(ctx, 'Primero');
    await t.pump(const Duration(milliseconds: 300));
    AppToast.info(ctx, 'Segundo');
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Primero'), findsNothing);
    expect(find.text('Segundo'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('se ve por encima de un diálogo abierto', (t) async {
    final ctx = await _montar(t);
    showDialog(
        context: ctx,
        builder: (_) => const AlertDialog(content: Text('Diálogo')));
    await t.pumpAndSettle();
    AppToast.success(ctx, 'Guardado');
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Guardado'), findsOneWidget);
    // el toast está por encima del diálogo: el último Overlay entry
    final toast = t.getTopLeft(find.text('Guardado'));
    expect(toast.dy, greaterThan(t.getBottomLeft(find.text('Diálogo')).dy));
    await t.pump(const Duration(seconds: 5));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('el botón de cerrar lo descarta', (t) async {
    final ctx = await _montar(t);
    AppToast.warning(ctx, 'Atención');
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Atención'), findsNothing);
  });
}
