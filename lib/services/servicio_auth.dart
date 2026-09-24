import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class SesionUsuario {
  final String accessToken;
  final String rol;
  final String nombre;
  final int usuarioId;
  final String correo;

  const SesionUsuario({
    required this.accessToken,
    required this.rol,
    required this.nombre,
    required this.usuarioId,
    required this.correo,
  });
}

class AuthException implements Exception {
  final String mensaje;
  const AuthException(this.mensaje);

  @override
  String toString() => mensaje;
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SesionUsuario? _sesionActual;
  SesionUsuario? get sesionActual => _sesionActual;

  Future<SesionUsuario> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login/');

    http.Response respuesta;

    try {
      respuesta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'correo': correo.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw const AuthException(
        'No fue posible conectar con el servidor. Verifica tu conexión.',
      );
    }

    if (respuesta.statusCode == 200) {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

      final sesion = SesionUsuario(
        accessToken: datos['access_token'] as String,
        rol: datos['rol'] as String,
        nombre: datos['nombre'] as String,
        usuarioId: datos['usuario_id'] as int,
        correo: datos['correo'] as String,
      );

      _sesionActual = sesion;
      await _guardarSesion(sesion);
      notifyListeners();

      return sesion;
    }

    if (respuesta.statusCode == 401) {
      throw const AuthException('Correo o contraseña incorrectos');
    }

    throw const AuthException(
      'No fue posible iniciar sesión. Intenta de nuevo más tarde.',
    );
  }

  Future<void> cerrarSesion() async {
    _sesionActual = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('rol');
    await prefs.remove('nombre');

    notifyListeners();
  }

  Future<void> _guardarSesion(SesionUsuario sesion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', sesion.accessToken);
    await prefs.setString('rol', sesion.rol);
    await prefs.setString('nombre', sesion.nombre);
  }
}
