import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/material_didactico.dart';
import 'api_config.dart';
import 'utilidad_fechas.dart';

class MaterialService extends ChangeNotifier {
  static final MaterialService _instance = MaterialService._internal();
  factory MaterialService() => _instance;
  MaterialService._internal();

  final List<MaterialDidactico> _materiales = [];
  bool _cargando = false;

  List<MaterialDidactico> get materiales {
    final lista = List<MaterialDidactico>.from(_materiales);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(lista);
  }

  bool get cargando => _cargando;

  MaterialDidactico _desdeJson(Map<String, dynamic> d) {
    final archivoBase64 = d['archivo_base64'] as String?;
    return MaterialDidactico(
      id: (d['id'] as int).toString(),
      cursoId: d['curso_id'] as int,
      titulo: d['titulo'] as String,
      descripcion: d['descripcion'] as String? ?? '',
      materia: d['materia'] as String? ?? '',
      enlace: d['enlace'] as String? ?? '',
      fecha: parsearFechaHoraUtc(d['fecha_creacion'] as String),
      archivoNombre: d['archivo_nombre'] as String? ?? '',
      archivoBytes: archivoBase64 != null && archivoBase64.isNotEmpty
          ? base64Decode(archivoBase64)
          : null,
    );
  }

  Future<void> cargarPorCursos(List<int> cursoIds) async {
    _cargando = true;
    notifyListeners();

    try {
      final resultados = <MaterialDidactico>[];

      for (final cursoId in cursoIds) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/materiales/').replace(
          queryParameters: {'curso_id': cursoId.toString()},
        );
        final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

        if (respuesta.statusCode == 200) {
          final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
          resultados.addAll(datos.map((d) => _desdeJson(d as Map<String, dynamic>)));
        }
      }

      _materiales
        ..clear()
        ..addAll(resultados);
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> agregar({
    required int cursoId,
    required String titulo,
    required String descripcion,
    required String materia,
    required String enlace,
    String? archivoNombre,
    Uint8List? archivoBytes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materiales/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'curso_id': cursoId,
              'titulo': titulo,
              'descripcion': descripcion,
              'materia': materia,
              'enlace': enlace,
              if (archivoNombre != null) 'archivo_nombre': archivoNombre,
              if (archivoBytes != null) 'archivo_base64': base64Encode(archivoBytes),
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _materiales.add(_desdeJson(datos));
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> eliminar(String id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materiales/$id');

    try {
      final respuesta = await http.delete(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 204) {
        _materiales.removeWhere((m) => m.id == id);
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
