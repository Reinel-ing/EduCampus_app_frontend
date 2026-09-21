import 'dart:typed_data';

class MaterialDidactico {
  final String id;
  String titulo;
  String descripcion;
  String grado;
  String materia;
  String enlace;
  DateTime fecha;
  String archivoNombre;
  Uint8List? archivoBytes;

  MaterialDidactico({
    required this.id,
    required this.titulo,
    this.descripcion = '',
    required this.grado,
    this.materia = '',
    this.enlace = '',
    DateTime? fecha,
    this.archivoNombre = '',
    this.archivoBytes,
  }) : fecha = fecha ?? DateTime.now();

  bool get tieneArchivo => archivoBytes != null && archivoBytes!.isNotEmpty;
}