import 'package:flutter/foundation.dart';
import '../models/situacion_convivencia.dart';

class ConvivenciaService extends ChangeNotifier {
  static final ConvivenciaService _instance = ConvivenciaService._internal();
  factory ConvivenciaService() => _instance;
  ConvivenciaService._internal();

  final List<SituacionConvivencia> _situaciones = [];

  List<SituacionConvivencia> get situaciones {
    final lista = List<SituacionConvivencia>.from(_situaciones);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(lista);
  }

  List<SituacionConvivencia> porEstudiante(String estudianteId) {
    return situaciones.where((s) => s.estudianteId == estudianteId).toList();
  }

  SituacionConvivencia agregar({
    required String estudianteId,
    required TipoSituacion tipo,
    required String titulo,
    required String descripcion,
  }) {
    final situacion = SituacionConvivencia(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      estudianteId: estudianteId,
      tipo: tipo,
      titulo: titulo,
      descripcion: descripcion,
    );
    _situaciones.add(situacion);
    notifyListeners();
    return situacion;
  }

  void marcarSeguimiento(String id, {required bool realizado, String nota = ''}) {
    final situacion = _situaciones.firstWhere((s) => s.id == id);
    situacion.seguimientoRealizado = realizado;
    if (nota.isNotEmpty) situacion.notaSeguimiento = nota;
    notifyListeners();
  }

  void eliminar(String id) {
    _situaciones.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}