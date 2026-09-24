import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/alerta_alumno.dart';
import '../models/estudiante.dart';
import 'api_config.dart';
import 'servicio_estudiantes.dart';
import 'utilidad_fechas.dart';

class AlertasService extends ChangeNotifier {
  static final AlertasService _instance = AlertasService._internal();
  factory AlertasService() => _instance;
  AlertasService._internal();

  final List<AlertaAlumno> _alertas = [];
  bool _cargando = false;
  bool _intentoCarga = false;

  List<AlertaAlumno> get alertas {
    final lista = List<AlertaAlumno>.from(_alertas);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  bool get cargando => _cargando;

  List<AlertaAlumno> get alertasPendientes =>
      alertas.where((a) => !a.atendida).toList();

  List<AlertaAlumno> get pendientes => alertasPendientes;

  NivelAlerta _nivelDesde(String v) {
    return NivelAlerta.values.firstWhere(
      (n) => n.name == v,
      orElse: () => NivelAlerta.informativo,
    );
  }

  AlertaAlumno _desdeJson(Map<String, dynamic> json) {
    final estudianteId = (json['student_id'] as int).toString();
    Student? estudiante;
    for (final s in StudentService().students) {
      if (s.id == estudianteId) {
        estudiante = s;
        break;
      }
    }

    return AlertaAlumno(
      id: (json['id'] as int).toString(),
      estudianteId: estudianteId,
      estudianteNombre: estudiante?.nombreCompleto ?? 'Estudiante',
      grado: estudiante?.grado ?? '',
      docenteNombre: json['docente_nombre'] as String? ?? 'Docente',
      descripcion: json['mensaje'] as String,
      nivel: _nivelDesde(json['severidad'] as String),
      fecha: parsearFechaHoraUtc(json['fecha'] as String),
      atendida: json['atendida'] as bool? ?? false,
      respuestaAdmin: json['respuesta_admin'] as String? ?? '',
    );
  }

  Future<void> cargarDesdeBackendSiHaceFalta() async {
    if (_intentoCarga) return;
    await cargarDesdeBackend();
  }

  Future<void> cargarDesdeBackend() async {
    _intentoCarga = true;
    _cargando = true;
    notifyListeners();

    try {
      if (StudentService().students.isEmpty) {
        await StudentService().cargarDesdeBackend();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/alertas/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        _alertas
          ..clear()
          ..addAll(datos.map((d) => _desdeJson(d as Map<String, dynamic>)));
      }
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> agregar({
    required String estudianteId,
    required String estudianteNombre,
    required String grado,
    required String docenteNombre,
    required String descripcion,
    required NivelAlerta nivel,
  }) async {
    final id = int.tryParse(estudianteId);
    if (id == null) return 'Estudiante inválido';

    final uri = Uri.parse('${ApiConfig.baseUrl}/alertas/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': id,
              'docente_nombre': docenteNombre,
              'mensaje': descripcion,
              'severidad': nivel.name,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _alertas.add(_desdeJson(datos));
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> atender(String id, {required String respuesta}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/alertas/$id/atender');

    try {
      final respuestaHttp = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'respuesta_admin': respuesta}),
          )
          .timeout(const Duration(seconds: 45));

      if (respuestaHttp.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuestaHttp.bodyBytes));
        final actualizada = _desdeJson(datos);
        final index = _alertas.indexWhere((a) => a.id == id);
        if (index != -1) _alertas[index] = actualizada;
        notifyListeners();
        return null;
      }

      return _extraerError(respuestaHttp);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  String _extraerError(http.Response respuesta) {
    try {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      final detalle = datos['detail'];
      if (detalle is String) return detalle;
    } catch (_) {}
    return 'No fue posible completar la operación.';
  }
}
