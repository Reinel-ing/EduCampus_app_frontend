import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'servicio_auth.dart';

class CuentaCreada {
  final int id;
  final String nombre;
  final String correo;
  final String rol;

  const CuentaCreada({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });
}

String generarPasswordSegura() {
  const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const minusculas = 'abcdefghjkmnpqrstuvwxyz';
  const digitos = '23456789';
  const especiales = '!@#%&*';

  final random = Random.secure();

  String tomar(String origen, int cantidad) => List.generate(
        cantidad,
        (_) => origen[random.nextInt(origen.length)],
      ).join();

  final password = [
    tomar(letras, 2),
    tomar(minusculas, 4),
    tomar(digitos, 3),
    tomar(especiales, 1),
  ].join().split('')..shuffle(random);

  return password.join();
}

class AdminService {
  Future<CuentaCreada> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    String? telefono,
    String? especialidad,
    int? gradoId,
    int? acudienteId,
  }) async {
    final sesion = AuthService().sesionActual;

    if (sesion == null) {
      throw const AuthException('Debes iniciar sesión como administrador');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/registro/').replace(
      queryParameters: {'access_token': sesion.accessToken},
    );

    http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombre': nombre,
              'correo': correo.trim().toLowerCase(),
              'password': password,
              'rol': rol,
              if (telefono != null) 'telefono': telefono,
              if (especialidad != null) 'especialidad': especialidad,
              if (gradoId != null) 'grado_id': gradoId,
              if (acudienteId != null) 'acudiente_id': acudienteId,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw const AuthException(
        'No fue posible conectar con el servidor. Verifica tu conexión.',
      );
    }

    if (respuesta.statusCode == 201) {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      return CuentaCreada(
        id: datos['id'] as int,
        nombre: datos['nombre'] as String,
        correo: datos['correo'] as String,
        rol: datos['rol'] as String,
      );
    }

    throw AuthException(_extraerMensajeError(respuesta));
  }

  Future<void> restablecerPassword({
    required String correo,
    required String rol,
    required String password,
  }) async {
    final sesion = AuthService().sesionActual;

    if (sesion == null) {
      throw const AuthException('Debes iniciar sesión como administrador');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/restablecer-password/').replace(
      queryParameters: {'access_token': sesion.accessToken},
    );

    http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'correo': correo.trim().toLowerCase(),
              'rol': rol,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw const AuthException(
        'No fue posible conectar con el servidor. Verifica tu conexión.',
      );
    }

    if (respuesta.statusCode == 200) return;

    throw AuthException(_extraerMensajeError(respuesta));
  }

  /// Devuelve la contraseña actual de la cuenta si el backend puede
  /// descifrarla (se creó o se restableció después de activar esta
  /// función), o null si no hay una copia recuperable.
  Future<String?> consultarPassword(String correo) async {
    final sesion = AuthService().sesionActual;
    if (sesion == null) return null;

    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/consultar-password/').replace(
      queryParameters: {
        'correo': correo.trim().toLowerCase(),
        'access_token': sesion.accessToken,
      },
    );

    try {
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
      if (respuesta.statusCode != 200) return null;
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      return datos['password'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _extraerMensajeError(http.Response respuesta) {
    try {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      final detalle = datos['detail'];

      if (detalle is String) return detalle;

      if (detalle is List && detalle.isNotEmpty) {
        final mensaje = detalle.first['msg'] as String? ?? 'Datos inválidos';
        return mensaje.replaceFirst('Value error, ', '');
      }
    } catch (_) {}

    return 'No fue posible completar el registro. Intenta de nuevo.';
  }
}
