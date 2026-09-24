import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AsistenciaEstudianteBackend {
  final int studentId;
  final String status;
  final String fecha;

  const AsistenciaEstudianteBackend({
    required this.studentId,
    required this.status,
    required this.fecha,
  });

  factory AsistenciaEstudianteBackend.fromJson(Map<String, dynamic> json) {
    return AsistenciaEstudianteBackend(
      studentId: json['student_id'] as int,
      status: json['status'] as String,
      fecha: json['fecha'] as String,
    );
  }
}

class AsistenciaDocenteBackend {
  final int profesorId;
  final String fecha;
  final bool presente;
  final bool completo;
  final String? observacion;

  const AsistenciaDocenteBackend({
    required this.profesorId,
    required this.fecha,
    required this.presente,
    required this.completo,
    this.observacion,
  });

  factory AsistenciaDocenteBackend.fromJson(Map<String, dynamic> json) {
    return AsistenciaDocenteBackend(
      profesorId: json['profesor_id'] as int,
      fecha: json['fecha'] as String,
      presente: json['presente'] as bool,
      completo: json['completo'] as bool,
      observacion: json['observacion'] as String?,
    );
  }
}

String formatearFechaISO(DateTime fecha) {
  return '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
}

class AsistenciaBackendService {
  Future<void> marcarEstudiante({
    required int studentId,
    required int courseId,
    required String status,
    required DateTime fecha,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/asistencias/');
    await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': studentId,
            'course_id': courseId,
            'status': status,
            'fecha': formatearFechaISO(fecha),
          }),
        )
        .timeout(const Duration(seconds: 45));
  }

  Future<List<AsistenciaEstudianteBackend>> listarPorCurso({
    required int courseId,
    required DateTime fecha,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/asistencias/').replace(
      queryParameters: {
        'course_id': courseId.toString(),
        'fecha': formatearFechaISO(fecha),
      },
    );

    final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

    if (respuesta.statusCode != 200) return [];

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

    return datos
        .map((d) => AsistenciaEstudianteBackend.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarDocente({
    required int profesorId,
    required DateTime fecha,
    required bool presente,
    required bool completo,
    String? observacion,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/asistencia-docentes/');
    await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'profesor_id': profesorId,
            'fecha': formatearFechaISO(fecha),
            'presente': presente,
            'completo': completo,
            if (observacion != null && observacion.isNotEmpty) 'observacion': observacion,
          }),
        )
        .timeout(const Duration(seconds: 45));
  }

  Future<List<AsistenciaDocenteBackend>> listarDocentes(DateTime fecha) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/asistencia-docentes/').replace(
      queryParameters: {'fecha': formatearFechaISO(fecha)},
    );

    final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

    if (respuesta.statusCode != 200) return [];

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

    return datos
        .map((d) => AsistenciaDocenteBackend.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  String urlReporteDiario(DateTime fecha) {
    return '${ApiConfig.baseUrl}/reportes/asistencia-diaria/?fecha=${formatearFechaISO(fecha)}';
  }
}
