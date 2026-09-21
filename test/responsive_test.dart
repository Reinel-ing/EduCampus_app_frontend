import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:educampus_app/screens/acudiente/panel_acudiente.dart';
import 'package:educampus_app/screens/admin/panel_admin.dart';
import 'package:educampus_app/screens/auth/pantalla_inicio_sesion.dart';
import 'package:educampus_app/screens/docente/panel_docente.dart';

const _tamanos = <String, Size>{
  'telefono pequeno (320x568)': Size(320, 568),
  'telefono (390x844)': Size(390, 844),
  'tablet (768x1024)': Size(768, 1024),
  'escritorio (1366x768)': Size(1366, 768),
};

void _abrirSinDesbordes(String nombre, Widget Function() panel) {
  _tamanos.forEach((etiqueta, tamano) {
    testWidgets('$nombre en $etiqueta: sin desbordes en ninguna opcion',
        (tester) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: panel()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'al abrir $nombre');

      final movil = tamano.width < 900;
      final total = movil
          ? await _contarOpcionesMovil(tester)
          : find.byType(ListTile).evaluate().length;

      for (var i = 0; i < total; i++) {
        if (movil) {
          await tester.tap(find.byTooltip('Open navigation menu'));
          await tester.pumpAndSettle();
        }
        final tile = find.byType(ListTile).at(i);
        await tester.ensureVisible(tile);
        await tester.tap(tile, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '$nombre, opcion #$i en $etiqueta');
      }
    });
  });
}

Future<int> _contarOpcionesMovil(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  final n = find.byType(ListTile).evaluate().length;
  await tester.tapAt(const Offset(5, 300)); // cierra el menu
  await tester.pumpAndSettle();
  return n;
}

void main() {
  _abrirSinDesbordes('Administrador', () => const AdminDashboard());
  _abrirSinDesbordes('Docente', () => const DocenteDashboard());
  _abrirSinDesbordes('Acudiente', () => const AcudienteDashboard());

  for (final e in _tamanos.entries) {
    testWidgets('Login en ${e.key}: sin desbordes', (tester) async {
      tester.view.physicalSize = e.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
