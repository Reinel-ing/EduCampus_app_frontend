import 'package:flutter/foundation.dart';
import '../models/clase_finalizada.dart';

class ClasesService extends ChangeNotifier {
  static final ClasesService _instance = ClasesService._internal();
  factory ClasesService() => _instance;
  ClasesService._internal();

  final List<ClaseFinalizada> _clases = [];

  List<ClaseFinalizada> get clases {
    final lista = List<ClaseFinalizada>.from(_clases);
    lista.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return lista;
  }

  List<ClaseFinalizada> get noVistas => clases;

  void registrar({
    required String docenteNombre,
    required String materia,
    required String grado,
    String observacion = '',
  }) {
    _clases.add(ClaseFinalizada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      docenteNombre: docenteNombre,
      materia: materia,
      grado: grado,
      observacion: observacion,
    ));
    notifyListeners();
  }
}