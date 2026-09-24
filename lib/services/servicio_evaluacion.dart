import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/registro_academico.dart';
import 'api_config.dart';

class EvaluacionService extends ChangeNotifier {
  static final EvaluacionService _instance = EvaluacionService._internal();
  factory EvaluacionService() => _instance;
  EvaluacionService._internal();

  final List<RegistroAcademico> _registros = [];
  final List<ObservacionBoletin> _observaciones = [];
  final Map<int, String> _titulosCurso = {};
  bool _cargando = false;

  bool get cargando => _cargando;

  List<RegistroAcademico> get registros {
    final lista = List<RegistroAcademico>.from(_registros);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(lista);
  }

  List<RegistroAcademico> porEstudiante(String estudianteId) {
    return registros.where((r) => r.estudianteId == estudianteId).toList();
  }

  ObservacionBoletin? observacion(String estudianteId, String periodo) {
    for (final o in _observaciones) {
      if (o.estudianteId == estudianteId && o.periodo == periodo) return o;
    }
    return null;
  }

  double? promedioPorEstudiante(String estudianteId) {
    final notas = porEstudiante(estudianteId).map((r) => r.score).toList();
    if (notas.isEmpty) return null;
    return notas.reduce((a, b) => a + b) / notas.length;
  }

  Future<void> cargarPorEstudiantes(List<String> estudianteIds) async {
    _cargando = true;
    notifyListeners();

    try {
      final registros = <RegistroAcademico>[];
      final observaciones = <ObservacionBoletin>[];

      for (final estudianteId in estudianteIds) {
        final id = int.tryParse(estudianteId);
        if (id == null) continue;

        final uriCal = Uri.parse('${ApiConfig.baseUrl}/calificaciones/').replace(
          queryParameters: {'student_id': id.toString()},
        );
        final respCal = await http.get(uriCal).timeout(const Duration(seconds: 45));
        if (respCal.statusCode == 200) {
          final datos = jsonDecode(utf8.decode(respCal.bodyBytes)) as List;
          for (final c in datos) {
            final cursoId = c['course_id'] as int;
            if (!_titulosCurso.containsKey(cursoId)) {
              await _cargarTituloCurso(cursoId);
            }
            registros.add(RegistroAcademico(
              id: (c['id'] as int).toString(),
              estudianteId: estudianteId,
              cursoId: cursoId,
              cursoTitulo: _titulosCurso[cursoId] ?? 'Curso',
              periodo: c['periodo'] as String,
              score: (c['score'] as num).toDouble(),
              logro: c['logro'] as String? ?? '',
            ));
          }
        }

        final uriObs = Uri.parse('${ApiConfig.baseUrl}/observaciones/').replace(
          queryParameters: {'student_id': id.toString()},
        );
        final respObs = await http.get(uriObs).timeout(const Duration(seconds: 45));
        if (respObs.statusCode == 200) {
          final datos = jsonDecode(utf8.decode(respObs.bodyBytes)) as List;
          for (final o in datos) {
            observaciones.add(ObservacionBoletin(
              id: (o['id'] as int).toString(),
              estudianteId: estudianteId,
              periodo: o['periodo'] as String,
              texto: o['texto'] as String,
            ));
          }
        }
      }

      _registros
        ..clear()
        ..addAll(registros);
      _observaciones
        ..clear()
        ..addAll(observaciones);
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _cargarTituloCurso(int cursoId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        for (final c in datos) {
          _titulosCurso[c['id'] as int] = c['title'] as String;
        }
      }
    } catch (_) {}
  }

  Future<String?> agregar({
    required String estudianteId,
    required int cursoId,
    required String cursoTitulo,
    required String periodo,
    required double score,
    String logro = '',
  }) async {
    final id = int.tryParse(estudianteId);
    if (id == null) return 'Estudiante inválido';

    final uri = Uri.parse('${ApiConfig.baseUrl}/calificaciones/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': id,
              'course_id': cursoId,
              'score': score,
              'logro': logro,
              'periodo': periodo,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _titulosCurso[cursoId] = cursoTitulo;
        _registros.removeWhere((r) =>
            r.estudianteId == estudianteId && r.cursoId == cursoId && r.periodo == periodo);
        _registros.add(RegistroAcademico(
          id: (datos['id'] as int).toString(),
          estudianteId: estudianteId,
          cursoId: cursoId,
          cursoTitulo: cursoTitulo,
          periodo: periodo,
          score: (datos['score'] as num).toDouble(),
          logro: datos['logro'] as String? ?? '',
        ));
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> eliminar(String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/calificaciones/$id');

    try {
      final respuesta = await http.delete(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 204) {
        _registros.removeWhere((r) => r.id == id);
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> guardarObservacion({
    required String estudianteId,
    required String periodo,
    required String texto,
  }) async {
    final id = int.tryParse(estudianteId);
    if (id == null) return 'Estudiante inválido';

    final uri = Uri.parse('${ApiConfig.baseUrl}/observaciones/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': id,
              'periodo': periodo,
              'texto': texto,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _observaciones.removeWhere((o) => o.estudianteId == estudianteId && o.periodo == periodo);
        _observaciones.add(ObservacionBoletin(
          id: (datos['id'] as int).toString(),
          estudianteId: estudianteId,
          periodo: periodo,
          texto: datos['texto'] as String,
        ));
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
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
