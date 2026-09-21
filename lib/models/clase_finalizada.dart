class ClaseFinalizada {
  final String id;
  final String docenteNombre;
  final String materia;
  final String grado;
  final String observacion;
  final DateTime fechaHora;

  ClaseFinalizada({
    required this.id,
    required this.docenteNombre,
    required this.materia,
    required this.grado,
    this.observacion = '',
    DateTime? fechaHora,
  }) : fechaHora = fechaHora ?? DateTime.now();
}