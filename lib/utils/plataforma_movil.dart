import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'archivo_elegido.dart';

/// Abre el selector de archivos del sistema. Devuelve null si se cancela.
/// [extensiones] puede venir con o sin punto ('.pdf' o 'pdf').
Future<ArchivoElegido?> seleccionarArchivo({
  List<String> extensiones = const [],
  bool soloImagenes = false,
}) async {
  final List<PlatformFile> resultado;

  if (soloImagenes) {
    resultado = await FilePicker.pickFiles(type: FileType.image);
  } else if (extensiones.isNotEmpty) {
    resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensiones
          .map((e) => e.replaceFirst('.', ''))
          .toList(),
    );
  } else {
    resultado = await FilePicker.pickFiles();
  }

  if (resultado.isEmpty) return null;
  final archivo = resultado.first;
  return ArchivoElegido(archivo.name, await archivo.readAsBytes());
}

/// Guarda el archivo temporalmente y lo abre con una app compatible.
Future<void> descargarBytes(String nombre, Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final nombreSeguro = nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final archivo = File('${dir.path}/$nombreSeguro');
  await archivo.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(archivo.path);
}

/// Abre una URL en el navegador o app externa (p. ej. WhatsApp).
Future<void> abrirUrlExterna(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

bool instalacionPwaDisponible() => false;

Future<String> instalarPwa() async => 'unavailable';

String? leerAlmacenLocal(String clave) => null;

void escribirAlmacenLocal(String clave, String valor) {}
