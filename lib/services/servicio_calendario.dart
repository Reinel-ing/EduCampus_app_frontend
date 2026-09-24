import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/evento_calendario.dart';
import 'api_config.dart';
import 'servicio_auth.dart';

class CalendarioService extends ChangeNotifier {
  static final CalendarioService _instance = CalendarioService._internal();
  factory CalendarioService() => _instance;
  CalendarioService._internal();

  final List<EventoCalendario> _eventos = [];
  bool _cargando = false;

  List<EventoCalendario> get eventos {
    final lista = List<EventoCalendario>.from(_eventos);
    lista.sort((a, b) => a.fecha.compareTo(b.fecha));
    return List.unmodifiable(lista);
  }

  bool get cargando => _cargando;

  Future<void> cargarDesdeBackend() async {
    _cargando = true;
    notifyListeners();

    try {
      final sesion = AuthService().sesionActual;
      if (sesion == null) return;

      final uri = Uri.parse('${ApiConfig.baseUrl}/eventos-calendario/').replace(
        queryParameters: {'access_token': sesion.accessToken},
      );

      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

        _eventos
          ..clear()
          ..addAll(datos.map((e) => EventoCalendario(
                id: (e['id'] as int).toString(),
                titulo: e['titulo'] as String,
                descripcion: e['descripcion'] as String? ?? '',
                fecha: DateTime.parse(e['fecha'] as String),
              )));
      }
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> agregar({
    required String titulo,
    required String descripcion,
    required DateTime fecha,
  }) async {
    final sesion = AuthService().sesionActual;
    if (sesion == null) return 'Debes iniciar sesión como administrador';

    final uri = Uri.parse('${ApiConfig.baseUrl}/eventos-calendario/').replace(
      queryParameters: {'access_token': sesion.accessToken},
    );

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'titulo': titulo,
              'descripcion': descripcion,
              'fecha': '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _eventos.add(EventoCalendario(
          id: (datos['id'] as int).toString(),
          titulo: datos['titulo'] as String,
          descripcion: datos['descripcion'] as String? ?? '',
          fecha: DateTime.parse(datos['fecha'] as String),
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
    final sesion = AuthService().sesionActual;
    if (sesion == null) return 'Debes iniciar sesión como administrador';

    final uri = Uri.parse('${ApiConfig.baseUrl}/eventos-calendario/$id').replace(
      queryParameters: {'access_token': sesion.accessToken},
    );

    try {
      final respuesta = await http.delete(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 204) {
        _eventos.removeWhere((e) => e.id == id);
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
