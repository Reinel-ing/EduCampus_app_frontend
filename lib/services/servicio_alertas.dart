import 'package:flutter/foundation.dart';
import '../models/alerta_alumno.dart';

class AlertasService extends ChangeNotifier {
  static final AlertasService _instance = AlertasService._internal();
  factory AlertasService() => _instance;
  AlertasService._internal();

  final List<AlertaAlumno> _alertas = [];

  List<AlertaAlumno> get alertas {
    final lista = List<AlertaAlumno>.from(_alertas);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  List<AlertaAlumno> get alertasPendientes =>
      alertas.where((a) => !a.atendida).toList();

  List<AlertaAlumno> get pendientes => alertasPendientes;

  void agregar({
    required String estudianteId,
    required String estudianteNombre,
    required String grado,
    required String docenteNombre,
    required String descripcion,
    required NivelAlerta nivel,
  }) {
    _alertas.add(AlertaAlumno(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      estudianteId: estudianteId,
      estudianteNombre: estudianteNombre,
      grado: grado,
      docenteNombre: docenteNombre,
      descripcion: descripcion,
      nivel: nivel,
    ));
    notifyListeners();
  }

  void atender(String id, {required String respuesta}) {
    final index = _alertas.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alertas[index].atendida = true;
      _alertas[index].respuestaAdmin = respuesta;
      notifyListeners();
    }
  }
}