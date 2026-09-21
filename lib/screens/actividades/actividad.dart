class Actividad {
  final String id;
  String materia;
  String grado;
  String titulo;
  String descripcion;
  String guiaUrl;
  DateTime fechaEntrega;
  DateTime fechaCreacion;

  Actividad({
    required this.id,
    required this.materia,
    required this.grado,
    required this.titulo,
    required this.descripcion,
    required this.fechaEntrega,
    this.guiaUrl = '',
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();
}

enum EstadoEntrega { pendiente, entregado, revisado }

extension EstadoEntregaLabel on EstadoEntrega {
  String get etiqueta {
    switch (this) {
      case EstadoEntrega.pendiente: return 'Pendiente';
      case EstadoEntrega.entregado: return 'Entregado';
      case EstadoEntrega.revisado: return 'Revisado';
    }
  }
}

class Entrega {
  final String id;
  final String actividadId;
  final String estudianteId;
  EstadoEntrega estado;
  String archivoUrl;
  String comentarioAcudiente;
  String retroalimentacion;

  Entrega({
    required this.id,
    required this.actividadId,
    required this.estudianteId,
    this.estado = EstadoEntrega.pendiente,
    this.archivoUrl = '',
    this.comentarioAcudiente = '',
    this.retroalimentacion = '',
  });
}