import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'servicio_auth.dart';

class FirmaItem {
  final int id;
  final String nombre;
  final bool tieneFirma;

  const FirmaItem({required this.id, required this.nombre, required this.tieneFirma});

  factory FirmaItem.fromJson(Map<String, dynamic> json) {
    return FirmaItem(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      tieneFirma: json['tiene_firma'] as bool,
    );
  }
}

class FirmasListado {
  final List<FirmaItem> docentes;
  final FirmaItem? admin;

  const FirmasListado({required this.docentes, this.admin});
}

class FirmasService {
  Future<FirmasListado> listar() async {
    final sesion = AuthService().sesionActual;
    if (sesion == null) throw const AuthException('Debes iniciar sesión como administrador');

    final uri = Uri.parse('${ApiConfig.baseUrl}/firmas/').replace(
      queryParameters: {'access_token': sesion.accessToken},
    );

    final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

    if (respuesta.statusCode != 200) {
      throw AuthException(_extraerError(respuesta));
    }

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    final docentes = (datos['docentes'] as List)
        .map((d) => FirmaItem.fromJson(d as Map<String, dynamic>))
        .toList();
    final admin = datos['admin'] != null ? FirmaItem.fromJson(datos['admin'] as Map<String, dynamic>) : null;

    return FirmasListado(docentes: docentes, admin: admin);
  }

  Future<String?> subirFirmaDocente(int profesorId, Uint8List bytes) async {
    return _subir('/firmas/docente/$profesorId/', bytes);
  }

  Future<String?> subirFirmaAdmin(int adminId, Uint8List bytes) async {
    return _subir('/firmas/admin/$adminId/', bytes);
  }

  Future<String?> _subir(String path, Uint8List bytes) async {
    final sesion = AuthService().sesionActual;
    if (sesion == null) return 'Debes iniciar sesión como administrador';

    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: {'access_token': sesion.accessToken},
    );

    try {
      final respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'imagen_base64': base64Encode(bytes)}),
          )
          .timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) return null;

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
