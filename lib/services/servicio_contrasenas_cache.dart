// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// Recuerda, solo en este navegador, la ultima contrasena generada para cada
/// correo (al crear la cuenta o al restablecerla). El backend nunca guarda
/// ni expone la contrasena en texto plano; esto es unicamente una nota local
/// de conveniencia para el administrador que la genero, no una fuente real
/// de verdad ni algo compartido con nadie mas.
class ContrasenasCache {
  static const _clave = 'educampus_contrasenas';

  static Map<String, String> _leerTodo() {
    try {
      final crudo = html.window.localStorage[_clave];
      if (crudo == null || crudo.isEmpty) return {};
      final datos = jsonDecode(crudo) as Map<String, dynamic>;
      return datos.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  static void guardar(String correo, String contrasena) {
    try {
      final todo = _leerTodo();
      todo[correo.trim().toLowerCase()] = contrasena;
      html.window.localStorage[_clave] = jsonEncode(todo);
    } catch (_) {}
  }

  static String? obtener(String correo) {
    return _leerTodo()[correo.trim().toLowerCase()];
  }
}
