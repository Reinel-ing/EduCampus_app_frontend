enum TipoRegistroAcademico { nota, logro, observacion }

extension TipoRegistroAcademicoLabel on TipoRegistroAcademico {
  String get etiqueta {
    switch (this) {
      case TipoRegistroAcademico.nota:
        return 'Nota';
      case TipoRegistroAcademico.logro:
        return 'Logro';
      case TipoRegistroAcademico.observacion:
        return 'Observación';
    }
  }
}

class RegistroAcademico {
  final String id;
  final String estudianteId;
  String materia;
  TipoRegistroAcademico tipo;
  String titulo;
  String descripcion;
  double? calificacion;
  DateTime fecha;

  RegistroAcademico({
    required this.id,
    required this.estudianteId,
    required this.materia,
    required this.tipo,
    required this.titulo,
    this.descripcion = '',
    this.calificacion,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}