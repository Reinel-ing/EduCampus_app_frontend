import 'package:flutter/foundation.dart';
import '../models/asistencia.dart';

class AsistenciaService extends ChangeNotifier {
  static final AsistenciaService _instance = AsistenciaService._internal();
  factory AsistenciaService() => _instance;
  AsistenciaService._internal();

  final List<RegistroAsistencia> _registros = [];

  List<RegistroAsistencia> get registros => List.unmodifiable(_registros);

  DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

  List<RegistroAsistencia> porFecha(DateTime fecha) {
    final dia = _soloFecha(fecha);
    return _registros.where((r) => _soloFecha(r.fecha) == dia).toList();
  }

  EstadoAsistencia? estadoDe(String estudianteId, DateTime fecha) {
    final dia = _soloFecha(fecha);
    final existentes = _registros.where(
      (r) => r.estudianteId == estudianteId && _soloFecha(r.fecha) == dia,
    );
    return existentes.isEmpty ? null : existentes.first.estado;
  }

  void marcar({required String estudianteId, required DateTime fecha, required EstadoAsistencia estado}) {
    final dia = _soloFecha(fecha);
    final index = _registros.indexWhere(
      (r) => r.estudianteId == estudianteId && _soloFecha(r.fecha) == dia,
    );
    if (index != -1) {
      _registros[index].estado = estado;
    } else {
      _registros.add(RegistroAsistencia(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        estudianteId: estudianteId,
        fecha: dia,
        estado: estado,
      ));
    }
    notifyListeners();
  }

  double porcentajeAsistenciaHoy() {
    final hoy = porFecha(DateTime.now());
    if (hoy.isEmpty) return 0;
    final presentes = hoy
        .where((r) => r.estado == EstadoAsistencia.presente || r.estado == EstadoAsistencia.tarde)
        .length;
    return presentes / hoy.length;
  }
}