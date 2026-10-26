import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ no importa APIs web fuera de la implementación web', () {
    final prohibidos = RegExp(
      r'''^\s*import\s+['"]dart:(html|js_interop|js|js_util)['"]''',
      multiLine: true,
    );
    final culpables = <String>[];

    for (final archivo
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((archivo) => archivo.path.endsWith('.dart'))) {
      if (archivo.path
          .replaceAll('\\', '/')
          .endsWith('utils/plataforma_web.dart')) {
        continue;
      }
      if (prohibidos.hasMatch(archivo.readAsStringSync())) {
        culpables.add(archivo.path);
      }
    }

    expect(culpables, isEmpty, reason: 'Imports web-only en: $culpables');
  });
}
