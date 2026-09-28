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
    await prefs.remove('usuario_id');
    await prefs.remove('correo');

    notifyListeners();
  }

  /// Intenta restaurar la sesión guardada localmente, validándola contra
  /// el backend. Devuelve null si no hay sesión guardada o ya no es válida
  /// (por ejemplo, si el backend se reinició y perdió la sesión en memoria).
  Future<SesionUsuario?> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();

    // Antes la sesión se guardaba siempre, sin preguntar. Para que nadie
    // quede con una sesión vieja guardada sin haberlo decidido, la primera
    // vez que corre esta versión se borra cualquier sesión existente; de
    // ahí en adelante solo se guarda si el usuario acepta la pregunta.
    const migracionKey = 'sesion_opcional_migrada_v1';
    if (prefs.getBool(migracionKey) != true) {
      await cerrarSesion();
      await prefs.setBool(migracionKey, true);
      return null;
    }

    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) return null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/session/').replace(
        queryParameters: {'access_token': token},
      );

      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode != 200) {
        await cerrarSesion();
        return null;
      }

      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

      final sesion = SesionUsuario(
        accessToken: token,
        rol: datos['rol'] as String,
        nombre: datos['nombre'] as String,
        usuarioId: datos['usuario_id'] as int,
        correo: datos['correo'] as String,
      );

      _sesionActual = sesion;
      notifyListeners();

      return sesion;
    } catch (_) {
      return null;
    }
  }

  /// Guarda la sesión actual en el dispositivo para que se restaure
  /// automáticamente la próxima vez que se abra la app. Se llama solo
  /// si el usuario acepta cuando se le pregunta al iniciar sesión.
  Future<void> recordarSesion() async {
    if (_sesionActual != null) {
      await _guardarSesion(_sesionActual!);
    }
  }

  Future<void> _guardarSesion(SesionUsuario sesion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', sesion.accessToken);
    await prefs.setString('rol', sesion.rol);
    await prefs.setString('nombre', sesion.nombre);
    await prefs.setInt('usuario_id', sesion.usuarioId);
    await prefs.setString('correo', sesion.correo);
  }
}
