import 'dart:typed_data';

/// Archivo que el usuario eligió desde su dispositivo o navegador.
class ArchivoElegido {
  final String nombre;
  final Uint8List bytes;

  const ArchivoElegido(this.nombre, this.bytes);
}
