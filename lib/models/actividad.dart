class Actividad {
  final String id;
  final int cursoId;
  String titulo;
  String descripcion;
  DateTime fechaEntrega;
  DateTime fechaCreacion;
  bool permiteVideo;

  Actividad({
    required this.id,
    required this.cursoId,
    required this.titulo,
    required this.descripcion,
    required this.fechaEntrega,
    DateTime? fechaCreacion,
    this.permiteVideo = false,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();
}

class Entrega {
  final String id;
  final String actividadId;
  final String estudianteId;
  final String archivoTipo;
  final String nombreOriginal;
  final String comentario;
  final DateTime fechaEntrega;
  final double? nota;
  final String? retroalimentacion;

  const Entrega({
    required this.id,
    required this.actividadId,
    required this.estudianteId,
    required this.archivoTipo,
    required this.nombreOriginal,
    this.comentario = '',
    required this.fechaEntrega,
    this.nota,
    this.retroalimentacion,
  });

  bool get calificada => nota != null;
}
