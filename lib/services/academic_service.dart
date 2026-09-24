import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/materia.dart';
import '../models/horario_entry.dart';
import 'api_config.dart';

export '../models/horario_entry.dart';

const List<String> gradosDisponiblesAcademico = [
  'Prejardín',
  'Jardín',
  'Transición',
  'Primero',
  'Segundo',
  'Tercero',
  'Cuarto',
  'Quinto',
];

String _formatearHora(String horaBackend) {
  // El backend envía "HH:MM:SS"; la UI usa "HH:MM".
  final partes = horaBackend.split(':');
  if (partes.length < 2) return horaBackend;
  return '${partes[0]}:${partes[1]}';
}

class AcademicService extends ChangeNotifier {
  static final AcademicService _instance = AcademicService._internal();
  factory AcademicService() => _instance;
  AcademicService._internal();

  final List<Materia> _materias = [];
  final List<HorarioEntry> _horario = [];
  bool _cargando = false;

  static const List<Color> _paletaColores = [
    Color(0xFF2E5EAA),
    Color(0xFFF5A623),
    Color(0xFF4CAF50),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
  ];

  List<Materia> get materias => List.unmodifiable(_materias);
  List<HorarioEntry> get horario => List.unmodifiable(_horario);
  bool get cargando => _cargando;

  Materia? materiaById(String id) {
    for (final m in _materias) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> cargarDesdeBackend() async {
    _cargando = true;
    notifyListeners();

    try {
      final resultados = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/cursos/')).timeout(const Duration(seconds: 45)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/profesores/')).timeout(const Duration(seconds: 45)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/grados/')).timeout(const Duration(seconds: 45)),
      ]);

      final respCursos = resultados[0];
      final respProfesores = resultados[1];
      final respGrados = resultados[2];

      if (respCursos.statusCode != 200) return;

      final cursos = jsonDecode(utf8.decode(respCursos.bodyBytes)) as List;

      final nombresProfesores = <int, String>{};
      if (respProfesores.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respProfesores.bodyBytes)) as List;
        for (final p in datos) {
          nombresProfesores[p['id'] as int] = p['nombre'] as String;
        }
      }

      final nombresGrados = <int, String>{};
      if (respGrados.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respGrados.bodyBytes)) as List;
        for (final g in datos) {
          nombresGrados[g['id'] as int] = g['nombre'] as String;
        }
      }

      _materias.clear();
      for (var i = 0; i < cursos.length; i++) {
        final c = cursos[i];
        final instructorId = c['instructor_id'] as int?;
        final gradoId = c['grado_id'] as int?;
        _materias.add(Materia(
          id: (c['id'] as int).toString(),
          nombre: c['title'] as String,
          grado: gradoId != null ? (nombresGrados[gradoId] ?? '') : '',
          docenteNombre: instructorId != null ? (nombresProfesores[instructorId] ?? '') : '',
          instructorId: instructorId,
          color: _paletaColores[i % _paletaColores.length],
        ));
      }

      final horarios = <HorarioEntry>[];
      for (final curso in cursos) {
        final cursoId = curso['id'] as int;
        final uri = Uri.parse('${ApiConfig.baseUrl}/horarios/').replace(
          queryParameters: {'curso_id': cursoId.toString()},
        );
        final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
        if (respuesta.statusCode == 200) {
          final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
          for (final h in datos) {
            horarios.add(HorarioEntry(
              id: (h['id'] as int).toString(),
              materiaId: cursoId.toString(),
              dia: h['dia_semana'] as String,
              horaInicio: _formatearHora(h['hora_inicio'] as String),
              horaFin: _formatearHora(h['hora_fin'] as String),
            ));
          }
        }
      }

      _horario
        ..clear()
        ..addAll(horarios);
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> agregarMateria({
    required String nombre,
    required int instructorId,
    int? gradoId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': nombre,
              'instructor_id': instructorId,
              if (gradoId != null) 'grado_id': gradoId,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        await cargarDesdeBackend();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> eliminarMateria(String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/$id');

    try {
      final respuesta = await http.delete(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 204) {
        _materias.removeWhere((m) => m.id == id);
        _horario.removeWhere((h) => h.materiaId == id);
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> agregarHorarioEntry({
    required String materiaId,
    required String dia,
    required String horaInicio,
    required String horaFin,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/horarios/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'curso_id': int.parse(materiaId),
              'dia_semana': dia,
              'hora_inicio': '$horaInicio:00',
              'hora_fin': '$horaFin:00',
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _horario.add(HorarioEntry(
          id: (datos['id'] as int).toString(),
          materiaId: materiaId,
          dia: dia,
          horaInicio: horaInicio,
          horaFin: horaFin,
        ));
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> eliminarHorarioEntry(String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/horarios/$id');

    try {
      final respuesta = await http.delete(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 204) {
        _horario.removeWhere((h) => h.id == id);
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  List<HorarioEntry> horarioPorGrado(String grado) {
    final idsMaterias = _materias.where((m) => m.grado == grado).map((m) => m.id).toSet();
    return _horario.where((h) => idsMaterias.contains(h.materiaId)).toList();
  }

  List<HorarioEntry> horarioPorInstructorId(int instructorId) {
    final idsMaterias = _materias.where((m) => m.instructorId == instructorId).map((m) => m.id).toSet();
    return _horario.where((h) => idsMaterias.contains(h.materiaId)).toList();
  }

  List<HorarioEntry> horarioPorCursos(Set<String> cursoIds) {
    return _horario.where((h) => cursoIds.contains(h.materiaId)).toList();
  }

  List<Materia> materiasPorInstructorId(int instructorId) {
    return _materias.where((m) => m.instructorId == instructorId).toList();
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
