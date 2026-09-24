import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/actividad.dart';
import 'api_config.dart';

class ActividadesService extends ChangeNotifier {
  static final ActividadesService _instance = ActividadesService._internal();
  factory ActividadesService() => _instance;
  ActividadesService._internal();

  final List<Actividad> _actividades = [];
  final Map<String, List<Entrega>> _entregasPorTarea = {};
  bool _cargando = false;

  List<Actividad> get actividades {
    final lista = List<Actividad>.from(_actividades);
    lista.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    return List.unmodifiable(lista);
  }

  bool get cargando => _cargando;

  Actividad _actividadDesdeJson(Map<String, dynamic> t) {
    return Actividad(
      id: (t['id'] as int).toString(),
      cursoId: t['curso_id'] as int,
      titulo: t['titulo'] as String,
      descripcion: t['descripcion'] as String? ?? '',
      fechaEntrega: DateTime.parse(t['fecha_entrega'] as String),
      fechaCreacion: DateTime.parse(t['fecha_creacion'] as String),
      permiteVideo: t['permite_video'] as bool? ?? false,
    );
  }

  Entrega _entregaDesdeJson(Map<String, dynamic> e) {
    return Entrega(
      id: (e['id'] as int).toString(),
      actividadId: (e['tarea_id'] as int).toString(),
      estudianteId: (e['student_id'] as int).toString(),
      archivoTipo: e['archivo_tipo'] as String,
      nombreOriginal: e['nombre_original'] as String,
      comentario: e['comentario'] as String? ?? '',
      fechaEntrega: DateTime.parse(e['fecha_entrega'] as String),
      nota: (e['nota'] as num?)?.toDouble(),
      retroalimentacion: e['retroalimentacion'] as String?,
    );
  }

  Future<void> cargarPorCursos(List<int> cursoIds) async {
    _cargando = true;
    notifyListeners();

    try {
      final resultados = <Actividad>[];

      for (final cursoId in cursoIds) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/tareas/').replace(
          queryParameters: {'curso_id': cursoId.toString()},
        );
        final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

        if (respuesta.statusCode == 200) {
          final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
          resultados.addAll(datos.map((t) => _actividadDesdeJson(t as Map<String, dynamic>)));
        }
      }

      _actividades
        ..clear()
        ..addAll(resultados);

      for (final actividad in resultados) {
        await _cargarEntregas(actividad.id);
      }
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _cargarEntregas(String actividadId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/tareas/$actividadId/entregas/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        _entregasPorTarea[actividadId] =
            datos.map((e) => _entregaDesdeJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  List<Entrega> entregasPorActividad(String actividadId) =>
      List.unmodifiable(_entregasPorTarea[actividadId] ?? const []);

  Entrega? entregaDe(String actividadId, String estudianteId) {
    final lista = _entregasPorTarea[actividadId] ?? const [];
    for (final e in lista) {
      if (e.estudianteId == estudianteId) return e;
    }
    return null;
  }

  Future<String?> agregarActividad({
    required int cursoId,
    required String titulo,
    required String descripcion,
    required DateTime fechaEntrega,
    bool permiteVideo = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/tareas/');

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'curso_id': cursoId,
              'titulo': titulo,
              'descripcion': descripcion,
              'fecha_entrega': fechaEntrega.toIso8601String(),
              'permite_video': permiteVideo,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _actividades.add(_actividadDesdeJson(datos));
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> subirEntrega({
    required String actividadId,
    required int studentId,
    int? acudienteId,
    required String nombreArchivo,
    required Uint8List archivoBytes,
    String comentario = '',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/tareas/$actividadId/entregas/');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['student_id'] = studentId.toString()
        ..fields['comentario'] = comentario
        ..files.add(http.MultipartFile.fromBytes('archivo', archivoBytes, filename: nombreArchivo));

      if (acudienteId != null) {
        request.fields['acudiente_id'] = acudienteId.toString();
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final respuesta = await http.Response.fromStream(streamedResponse);

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final entrega = _entregaDesdeJson(datos);
        final lista = _entregasPorTarea.putIfAbsent(actividadId, () => []);
        lista.removeWhere((e) => e.estudianteId == entrega.estudianteId);
        lista.add(entrega);
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> calificarEntrega({
    required String entregaId,
    required String actividadId,
    required double nota,
    String? retroalimentacion,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entregas/$entregaId/calificar');

    try {
      final respuesta = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nota': nota,
              if (retroalimentacion != null) 'retroalimentacion': retroalimentacion,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final entregaActualizada = _entregaDesdeJson(datos);
        final lista = _entregasPorTarea[actividadId];
        if (lista != null) {
          final index = lista.indexWhere((e) => e.id == entregaId);
          if (index != -1) lista[index] = entregaActualizada;
        }
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  String urlDescargaEntrega(String entregaId) =>
      '${ApiConfig.baseUrl}/entregas/$entregaId/archivo';

  String _extraerError(http.Response respuesta) {
    try {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      final detalle = datos['detail'];
      if (detalle is String) return detalle;
    } catch (_) {}
    return 'No fue posible completar la operación.';
  }
}
