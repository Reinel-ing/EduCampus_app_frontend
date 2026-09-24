import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'servicio_auth.dart';

class NotificacionBackend {
  final int id;
  final int? acudienteId;
  final int? profesorId;
  final int? estudianteId;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime fecha;

  const NotificacionBackend({
    required this.id,
    required this.acudienteId,
    required this.profesorId,
    required this.estudianteId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fecha,
  });

  factory NotificacionBackend.fromJson(Map<String, dynamic> json) {
    return NotificacionBackend(
      id: json['id'] as int,
      acudienteId: json['acudiente_id'] as int?,
      profesorId: json['profesor_id'] as int?,
      estudianteId: json['estudiante_id'] as int?,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String,
      leida: json['leida'] as bool,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }
}

class AvisoRecogidaResultado {
  final int acudientesNotificados;
  final List<AvisoWhatsapp> whatsapp;

  const AvisoRecogidaResultado({
    required this.acudientesNotificados,
    required this.whatsapp,
  });
}

class AvisoWhatsapp {
  final String telefono;
  final String mensaje;

  const AvisoWhatsapp({required this.telefono, required this.mensaje});

  factory AvisoWhatsapp.fromJson(Map<String, dynamic> json) {
    return AvisoWhatsapp(
      telefono: json['telefono'] as String,
      mensaje: json['mensaje'] as String,
    );
  }
}

class NotificacionesBackendService {
  Future<List<NotificacionBackend>> obtenerParaAcudiente(int acudienteId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notificaciones/$acudienteId/');

    final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

    if (respuesta.statusCode != 200) return [];

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

    return datos
        .map((d) => NotificacionBackend.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificacionBackend>> obtenerParaDocente(int profesorId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notificaciones/docente/$profesorId/');

    final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

    if (respuesta.statusCode != 200) return [];

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

    return datos
        .map((d) => NotificacionBackend.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarLeida(int notificacionId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notificaciones/$notificacionId/marcar-leida/');
    await http.post(uri).timeout(const Duration(seconds: 45));
  }

  Future<AvisoRecogidaResultado> avisarRecogida(int courseId) async {
    final sesion = AuthService().sesionActual;

    if (sesion == null) {
      throw const AuthException('Debes iniciar sesión.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/avisar-recogida/').replace(
      queryParameters: {'access_token': sesion.accessToken},
    );

    http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'course_id': courseId}),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw const AuthException('No fue posible conectar con el servidor.');
    }

    if (respuesta.statusCode == 200) {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      final whatsapp = (datos['whatsapp'] as List? ?? [])
          .map((w) => AvisoWhatsapp.fromJson(w as Map<String, dynamic>))
          .toList();
      return AvisoRecogidaResultado(
        acudientesNotificados: datos['acudientes_notificados'] as int,
        whatsapp: whatsapp,
      );
    }

    throw AuthException(_extraerError(respuesta));
  }

  Future<void> crearAlerta({
    required int studentId,
    required String mensaje,
    required String severidad,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/alertas/');

    http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': studentId,
              'mensaje': mensaje,
              'severidad': severidad,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw const AuthException('No fue posible conectar con el servidor.');
    }

    if (respuesta.statusCode != 201) {
      throw AuthException(_extraerError(respuesta));
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
