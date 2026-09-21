class EventoCalendario {
  final String id;
  String titulo;
  String descripcion;
  DateTime fecha;

  EventoCalendario({
    required this.id,
    required this.titulo,
    this.descripcion = '',
    required this.fecha,
  });
}