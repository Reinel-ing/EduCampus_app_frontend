enum NivelAlerta { informativo, seguimiento, urgente }

extension NivelAlertaLabel on NivelAlerta {
  String get etiqueta {
    switch (this) {
      case NivelAlerta.informativo: return 'Informativo';
      case NivelAlerta.seguimiento: return 'Seguimiento';
      case NivelAlerta.urgente: return 'Urgente';
    }
  }
}

class AlertaAlumno {
  final String id;
  final String estudianteId;
  final String estudianteNombre;
  final String grado;
  final String docenteNombre;
  final String descripcion;
  final NivelAlerta nivel;
  final DateTime fecha;
  bool atendida;
  String respuestaAdmin;

  AlertaAlumno({
    required this.id,
    required this.estudianteId,
    required this.estudianteNombre,
    required this.grado,
    required this.docenteNombre,
    required this.descripcion,
    required this.nivel,
    DateTime? fecha,
    this.atendida = false,
    this.respuestaAdmin = '',
  }) : fecha = fecha ?? DateTime.now();
}