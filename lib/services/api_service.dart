import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Nota: Usa 'http://10.0.2.2:8000' si pruebas en el emulador de Android, 
  // o 'http://127.0.0.1:8000' si ejecutas en Windows Desktop / Web / Dispositivo físico.
  static const String baseUrl = "http://127.0.0.1:8000";

  // ==========================================
  // 1. MÓDULO DE USUARIOS
  // ==========================================
  static Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String correo,
    required String rol, // "estudiante", "profesor", etc.
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nombre,
          "email": correo,
          "role": rol,
        }),
      );

      if (response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {"success": false, "message": errorData["detail"] ?? "Error de validación"};
      }
    } catch (e) {
      return {"success": false, "message": "No se pudo conectar al servidor: $e"};
    }
  }

  static Future<List<dynamic>> obtenerUsuarios() async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar los usuarios");
    }
  }

  // ==========================================
  // 2. MÓDULO DE CURSOS
  // ==========================================
  static Future<Map<String, dynamic>> crearCurso({
    required String titulo,
    String? descripcion,
    required int instructorId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cursos/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": titulo,
        "description": descripcion,
        "instructor_id": instructorId,
      }),
    );

    if (response.statusCode == 201) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "message": "Error al crear el curso"};
    }
  }

  static Future<List<dynamic>> obtenerCursos() async {
    final response = await http.get(Uri.parse('$baseUrl/cursos/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar los cursos");
    }
  }

  // ==========================================
  // 3. MÓDULO DE MATRÍCULAS
  // ==========================================
  static Future<bool> matricularEstudiante({
    required int studentId,
    required int courseId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matriculas/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_id": studentId,
        "course_id": courseId,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> obtenerMatriculas() async {
    final response = await http.get(Uri.parse('$baseUrl/matriculas/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // ==========================================
  // 4. MÓDULO DE CALIFICACIONES / LOGROS
  // ==========================================
  static Future<bool> registrarCalificacion({
    required int studentId,
    required int courseId,
    required double score,
    String? feedback,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calificaciones/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_id": studentId,
        "course_id": courseId,
        "score": score,
        "feedback": feedback,
      }),
    );
    return response.statusCode == 201;
  }

  // ==========================================
  // 5. MÓDULO DE ASISTENCIAS
  // ==========================================
  static Future<bool> registrarAsistencia({
    required int studentId,
    required int courseId,
    required String status, // "presente", "ausente", "excusado"
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/asistencias/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_id": studentId,
        "course_id": courseId,
        "status": status,
      }),
    );
    return response.statusCode == 201;
  }

  // ==========================================
  // 6. MÓDULO DE HORARIOS
  // ==========================================
  static Future<bool> crearHorario({
    required int cursoId,
    required String diaSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/horarios/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "curso_id": cursoId,
        "dia_semana": diaSemana,
        "hora_inicio": horaInicio,
        "hora_fin": horaFin,
      }),
    );
    return response.statusCode == 201;
  }

  // ==========================================
  // 7. MÓDULO DE TAREAS
  // ==========================================
  static Future<bool> crearTarea({
    required int cursoId,
    required String titulo,
    String? descripcion,
    required String fechaEntrega, // Formato ISO 8601 (ej. "2026-06-01T23:59:59")
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tareas/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "curso_id": cursoId,
        "titulo": titulo,
        "descripcion": descripcion,
        "fecha_entrega": fechaEntrega,
      }),
    );
    return response.statusCode == 201;
  }
}