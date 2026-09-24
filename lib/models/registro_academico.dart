const periodosValidos = ['I', 'II', 'III', 'IV'];

class RegistroAcademico {
  final String id;
  final String estudianteId;
  final int cursoId;
  String cursoTitulo;
  String periodo;
  double score;
  String logro;
  DateTime fecha;

  RegistroAcademico({
    required this.id,
    required this.estudianteId,
    required this.cursoId,
    required this.cursoTitulo,
    required this.periodo,
    required this.score,
    this.logro = '',
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}

class ObservacionBoletin {
  final String id;
  final String estudianteId;
  final String periodo;
  String texto;

  ObservacionBoletin({
    required this.id,
    required this.estudianteId,
    required this.periodo,
    required this.texto,
  });
}
