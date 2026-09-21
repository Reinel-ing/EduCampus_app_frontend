const List<String> diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

class HorarioEntry {
  final String id;
  String materiaId;
  String dia;
  String horaInicio;
  String horaFin;

  HorarioEntry({
    required this.id,
    required this.materiaId,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
  });
}