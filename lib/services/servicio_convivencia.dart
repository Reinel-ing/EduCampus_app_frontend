import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/situacion_convivencia.dart';
import 'api_config.dart';

class ConvivenciaService extends ChangeNotifier {
  static final ConvivenciaService _instance = ConvivenciaService._internal();
  factory ConvivenciaService() => _instance;
  ConvivenciaService._internal();

  final List<SituacionConvivencia> _situaciones = [];
  bool _cargando = false;
  bool _intentoCarga = false;

  List<SituacionConvivencia> get situaciones {
    final lista = List<SituacionConvivencia>.from(_situaciones);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(lista);
  }

  bool get cargando => _cargando;

  List<SituacionConvivencia> porEstudiante(String estudianteId) {
    return situaciones.where((s) => s.estudianteId == estudianteId).toList();
  }

  TipoSituacion _tipoDesde(String v) {
    return TipoSituacion.values.firstWhere(
      (t) => t.name == v,
      orElse: () => TipoSituacion.neutral,
    );
  }

  SituacionConvivencia _desdeJson(Map<String, dynamic> json) {
    return SituacionConvivencia(
      id: (json['id'] as int).toString(),
      estudianteId: (json['student_id'] as int).toString(),
      tipo: _tipoDesde(json['tipo'] as String),
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['observacion'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      seguimientoRealizado: json['seguimiento_realizado'] as bool? ?? false,
      notaSeguimiento: json['nota_seguimiento'] as String? ?? '',
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
      final uri = Uri.parse('${ApiConfig.baseUrl}/convivencia/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        _situaciones
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
    required TipoSituacion tipo,
    required String titulo,
    required String descripcion,
  }) async {
    final id = int.tryParse(estudianteId);
    if (id == null) return 'Estudiante inválido';

    final uri = Uri.parse('${ApiConfig.baseUrl}/convivencia/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'student_id': id,
              'titulo': titulo,
              'observacion': descripcion,
              'tipo': tipo.name,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _situaciones.add(_desdeJson(datos));
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> marcarSeguimiento(String id, {required bool realizado, String nota = ''}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/convivencia/$id/seguimiento');

    try {
      final respuesta = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nota_seguimiento': nota}),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final actualizado = _desdeJson(datos);
        final index = _situaciones.indexWhere((s) => s.id == id);
        if (index != -1) _situaciones[index] = actualizado;
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> eliminar(String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/convivencia/$id');

    try {
      final respuesta = await http.delete(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 204) {
        _situaciones.removeWhere((s) => s.id == id);
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
