// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:typed_data';

import 'archivo_elegido.dart';

Future<ArchivoElegido?> seleccionarArchivo({
  List<String> extensiones = const [],
  bool soloImagenes = false,
}) {
  final completer = Completer<ArchivoElegido?>();
  final accept = soloImagenes
      ? 'image/*'
      : extensiones.map((e) => e.startsWith('.') ? e : '.$e').join(',');
  final input = html.FileUploadInputElement();
  if (accept.isNotEmpty) input.accept = accept;

  input.onChange.listen((_) {
    final file = input.files?.first;
    if (file == null) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (completer.isCompleted) return;
      if (result is List<int>) {
        completer.complete(
          ArchivoElegido(file.name, Uint8List.fromList(result)),
        );
      } else {
        completer.complete(null);
      }
    });
  });

  input.addEventListener('cancel', (_) {
    if (!completer.isCompleted) completer.complete(null);
  });
  input.click();
  return completer.future;
}

Future<void> descargarBytes(String nombre, Uint8List bytes) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> abrirUrlExterna(String url) async {
  html.window.open(url, '_blank');
}

@JS('eduCampusPuedeInstalar')
external bool _puedeInstalar();

@JS('eduCampusInstalarApp')
external JSPromise<JSString> _instalarApp();

bool instalacionPwaDisponible() {
  try {
    return _puedeInstalar();
  } catch (_) {
    return false;
  }
}

Future<String> instalarPwa() async {
  try {
    final resultado = await _instalarApp().toDart;
    return resultado.toDart;
  } catch (_) {
    return 'unavailable';
  }
}

String? leerAlmacenLocal(String clave) => html.window.localStorage[clave];

void escribirAlmacenLocal(String clave, String valor) {
  html.window.localStorage[clave] = valor;
}
