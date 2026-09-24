import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/estudiante.dart';
import '../models/campo_personalizado.dart';
import 'api_config.dart';

class StudentService extends ChangeNotifier {
  static final StudentService _instance = StudentService._internal();
  factory StudentService() => _instance;
  StudentService._internal();

  final List<Student> _students = [];
  final List<CustomField> _customFields = [];
  bool _cargando = false;

  List<Student> get students => List.unmodifiable(_students);
  List<CustomField> get customFields => List.unmodifiable(_customFields);
  bool get cargando => _cargando;

  Future<void> cargarDesdeBackend() async {
    _cargando = true;
    notifyListeners();

    try {
      final respuestas = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/grados/')).timeout(const Duration(seconds: 45)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/acudientes/')).timeout(const Duration(seconds: 45)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/estudiantes/')).timeout(const Duration(seconds: 45)),
      ]);

      if (respuestas.every((r) => r.statusCode == 200)) {
        final grados = <int, String>{
          for (final g in jsonDecode(utf8.decode(respuestas[0].bodyBytes)) as List)
            g['id'] as int: g['nombre'] as String,
        };

        final acudientes = <int, Map<String, String>>{
          for (final a in jsonDecode(utf8.decode(respuestas[1].bodyBytes)) as List)
            a['id'] as int: {
              'nombre': a['nombre'] as String? ?? '',
              'telefono': a['telefono'] as String? ?? '',
              'correo': a['correo'] as String? ?? '',
            },
        };

        final estudiantes = jsonDecode(utf8.decode(respuestas[2].bodyBytes)) as List;

        _students
          ..clear()
          ..addAll(estudiantes.map((e) => _desdeJson(
                e as Map<String, dynamic>,
                grados,
                acudientes,
              )));
      }
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Student _desdeJson(
    Map<String, dynamic> e,
    Map<int, String> grados,
    Map<int, Map<String, String>> acudientes,
  ) {
    final partes = (e['nombre'] as String? ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final nombres = partes.isNotEmpty ? partes.first : '';
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

    final gradoId = e['grado_id'] as int?;
    final acudienteId = e['acudiente_id'] as int?;
    final acudiente = acudienteId != null ? acudientes[acudienteId] : null;

    return Student(
      id: e['id'].toString(),
      nombres: nombres,
      apellidos: apellidos,
      fechaNacimiento: '',
      grado: gradoId != null ? (grados[gradoId] ?? '') : '',
      acudienteNombre: acudiente?['nombre'] ?? '',
      acudienteTelefono: acudiente?['telefono'] ?? '',
      acudienteParentesco: '',
      acudienteCorreo: acudiente?['correo'] ?? '',
    );
  }

  void addStudent(Student student) {
    _students.add(student);
    notifyListeners();
  }

  void updateStudent(Student student) {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      notifyListeners();
    }
  }

  void removeStudent(String id) {
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void addCustomField(
    String label, {
    TipoCampo tipo = TipoCampo.texto,
    List<String>? opciones,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _customFields.add(CustomField(id: id, label: label, tipo: tipo, opciones: opciones));
    notifyListeners();
  }

  void deleteCustomField(String id) {
    _customFields.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  List<Student> searchByName(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return _students
        .where((s) => s.nombreCompleto.toLowerCase().contains(q))
        .toList();
  }
}