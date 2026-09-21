enum RolNotificacion { admin, docente, acudiente }

class Notificacion {
  final String id;
  final RolNotificacion rol;
  final String? destinatarioId;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  bool leida;

  Notificacion({
    required this.id,
    required this.rol,
    this.destinatarioId,
    required this.titulo,
    required this.mensaje,
    DateTime? fecha,
    this.leida = false,
  }) : fecha = fecha ?? DateTime.now();
}