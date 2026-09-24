import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/docente.dart';
import 'api_config.dart';

class TeacherService extends ChangeNotifier {
  static final TeacherService _instance = TeacherService._internal();
  factory TeacherService() => _instance;
  TeacherService._internal();

  final List<Teacher> _teachers = [];
  bool _cargando = false;

  List<Teacher> get teachers => List.unmodifiable(_teachers);
  bool get cargando => _cargando;

  Future<void> cargarDesdeBackend() async {
    _cargando = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/profesores/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

        _teachers
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

  Teacher _desdeJson(Map<String, dynamic> d) {
    final partes = (d['correo'] == null ? '' : (d['nombre'] as String? ?? ''))
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final nombres = partes.isNotEmpty ? partes.first : (d['nombre'] as String? ?? '');
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

    return Teacher(
      id: d['id'].toString(),
      nombres: nombres,
      apellidos: apellidos,
      documento: '',
      especialidad: d['especialidad'] as String? ?? '',
      telefono: '',
      correo: d['correo'] as String? ?? '',
    );
  }

  static String generarPassword() {
    final now = DateTime.now();
    final parte1 = now.millisecondsSinceEpoch.toString().substring(7);
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final letra = letras[now.second % letras.length];
    return '$letra$parte1';
  }

  void addTeacher(Teacher teacher) {
    _teachers.add(teacher);
    notifyListeners();
  }

  void updateTeacher(Teacher teacher) {
    final index = _teachers.indexWhere((t) => t.id == teacher.id);
    if (index != -1) {
      _teachers[index] = teacher;
      notifyListeners();
    }
  }

  void deleteTeacher(String id) {
    _teachers.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<Teacher> searchByName(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return _teachers.where((t) => t.nombreCompleto.toLowerCase().contains(q)).toList();
  }
}