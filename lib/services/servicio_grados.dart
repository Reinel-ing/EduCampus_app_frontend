import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class GradoService extends ChangeNotifier {
  static final GradoService _instance = GradoService._internal();
  factory GradoService() => _instance;
  GradoService._internal();

  final List<String> _grados = [];
  final Map<String, int> _idsPorNombre = {};
  bool _cargando = false;

  List<String> get grados => List.unmodifiable(_grados);
  bool get cargando => _cargando;

  int? idPorNombre(String nombre) => _idsPorNombre[nombre];

  Future<void> cargarDesdeBackend() async {
    _cargando = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grados/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

        _grados.clear();
        _idsPorNombre.clear();

        for (final g in datos) {
          final nombre = g['nombre'] as String;
          _grados.add(nombre);
          _idsPorNombre[nombre] = g['id'] as int;
        }
      }
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> agregar(String nombre) async {
    final valor = nombre.trim();
    if (valor.isEmpty || _grados.contains(valor)) return null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grados/');
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nombre': valor}),
          )
          .timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 201) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        _grados.add(valor);
        _idsPorNombre[valor] = datos['id'] as int;
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> editar(String actual, String nuevo) async {
    final valor = nuevo.trim();
    final id = _idsPorNombre[actual];
    if (id == null || valor.isEmpty || _grados.contains(valor)) return null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grados/$id');
      final respuesta = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'nombre': valor}),
          )
          .timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final index = _grados.indexOf(actual);
        if (index != -1) _grados[index] = valor;
        _idsPorNombre.remove(actual);
        _idsPorNombre[valor] = id;
        notifyListeners();
        return null;
      }

      return _extraerError(respuesta);
    } catch (_) {
      return 'No fue posible conectar con el servidor.';
    }
  }

  Future<String?> eliminar(String nombre) async {
    final id = _idsPorNombre[nombre];
    if (id == null) return null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/grados/$id');
      final respuesta = await http.delete(uri).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 204) {
        _grados.remove(nombre);
        _idsPorNombre.remove(nombre);
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
