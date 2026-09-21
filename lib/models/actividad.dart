import 'dart:typed_data';

class Actividad {
  final String id;
  String materia;
  String grado;
  String titulo;
  String descripcion;
  DateTime fechaEntrega;
  DateTime fechaCreacion;
  String archivoNombre;
  Uint8List? archivoBytes;
  String guiaUrl;

  Actividad({
    required this.id,
    required this.materia,
    required this.grado,
    required this.titulo,
    required this.descripcion,
    required this.fechaEntrega,
    DateTime? fechaCreacion,
    this.archivoNombre = '',
    this.archivoBytes,
    this.guiaUrl = '',
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  bool get tieneArchivo => archivoBytes != null && archivoBytes!.isNotEmpty;
}

enum EstadoEntrega { pendiente, entregado, revisado }

extension EstadoEntregaLabel on EstadoEntrega {
  String get etiqueta {
    switch (this) {
      case EstadoEntrega.pendiente:
        return 'Pendiente';
      case EstadoEntrega.entregado:
        return 'Entregado';
      case EstadoEntrega.revisado:
        return 'Revisado';
    }
  }
}

class Entrega {
  final String id;
  final String actividadId;
  final String estudianteId;
  EstadoEntrega estado;
  String retroalimentacion;
  String archivoNombre;
  Uint8List? archivoBytes;
  String archivoUrl;
  String comentarioAcudiente;

  Entrega({
    required this.id,
    required this.actividadId,
    required this.estudianteId,
    this.estado = EstadoEntrega.pendiente,
    this.retroalimentacion = '',
    this.archivoNombre = '',
    this.archivoBytes,
    this.archivoUrl = '',
    this.comentarioAcudiente = '',
  });

  bool get tieneArchivo => archivoBytes != null && archivoBytes!.isNotEmpty;
}