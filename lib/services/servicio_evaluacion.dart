import 'package:flutter/foundation.dart';
import '../models/registro_academico.dart';

class EvaluacionService extends ChangeNotifier {
  static final EvaluacionService _instance = EvaluacionService._internal();
  factory EvaluacionService() => _instance;
  EvaluacionService._internal();

  final List<RegistroAcademico> _registros = [];

  List<RegistroAcademico> get registros {
    final lista = List<RegistroAcademico>.from(_registros);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(lista);
  }

  List<RegistroAcademico> porEstudiante(String estudianteId) {
    return registros.where((r) => r.estudianteId == estudianteId).toList();
  }

  RegistroAcademico agregar({
    required String estudianteId,
    required String materia,
    required TipoRegistroAcademico tipo,
    required String titulo,
    String descripcion = '',
    double? calificacion,
  }) {
    final registro = RegistroAcademico(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      estudianteId: estudianteId,
      materia: materia,
      tipo: tipo,
      titulo: titulo,
      descripcion: descripcion,
      calificacion: tipo == TipoRegistroAcademico.nota ? calificacion : null,
    );
    _registros.add(registro);
    notifyListeners();
    return registro;
  }

  void eliminar(String id) {
    _registros.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  double? promedioPorEstudiante(String estudianteId) {
    final notas = _registros
        .where((r) =>
            r.estudianteId == estudianteId &&
            r.tipo == TipoRegistroAcademico.nota &&
            r.calificacion != null)
        .map((r) => r.calificacion!)
        .toList();
    if (notas.isEmpty) return null;
    return notas.reduce((a, b) => a + b) / notas.length;
  }
}