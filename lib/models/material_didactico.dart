import 'dart:typed_data';

class MaterialDidactico {
  final String id;
  final int cursoId;
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
    required this.cursoId,
    required this.titulo,
    this.descripcion = '',
    this.grado = '',
    this.materia = '',
    this.enlace = '',
    DateTime? fecha,
    this.archivoNombre = '',
    this.archivoBytes,
  }) : fecha = fecha ?? DateTime.now();

  bool get tieneArchivo => archivoBytes != null && archivoBytes!.isNotEmpty;
}