enum EstadoAsistencia { presente, ausente, tarde, excusa }

extension EstadoAsistenciaLabel on EstadoAsistencia {
  String get etiqueta {
    switch (this) {
      case EstadoAsistencia.presente:
        return 'Presente';
      case EstadoAsistencia.ausente:
        return 'Ausente';
      case EstadoAsistencia.tarde:
        return 'Tarde';
      case EstadoAsistencia.excusa:
        return 'Excusa';
    }
  }
}

class RegistroAsistencia {
  final String id;
  final String estudianteId;
  final DateTime fecha;
  EstadoAsistencia estado;

  RegistroAsistencia({
    required this.id,
    required this.estudianteId,
    required this.fecha,
    required this.estado,
  });
}