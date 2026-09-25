import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../services/academic_service.dart';
import '../../services/api_config.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/weekly_schedule_grid.dart';

class HorarioAcudienteScreen extends StatefulWidget {
  const HorarioAcudienteScreen({super.key});

  @override
  State<HorarioAcudienteScreen> createState() => _HorarioAcudienteScreenState();
}

class _HorarioAcudienteScreenState extends State<HorarioAcudienteScreen> {
  bool _cargando = true;
  List<Student> _misEstudiantes = [];
  String? _estudianteSeleccionadoId;
  Set<String> _cursoIds = {};

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);

    final correo = AuthService().sesionActual?.correo;

    if (StudentService().students.isEmpty) {
      await StudentService().cargarDesdeBackend();
    }
    await AcademicService().cargarDesdeBackend();

    _misEstudiantes = StudentService()
        .students
        .where((s) => s.acudienteCorreo.trim().toLowerCase() == correo)
        .toList();

    _estudianteSeleccionadoId = _misEstudiantes.isNotEmpty ? _misEstudiantes.first.id : null;

    await _cargarCursosDelEstudiante();

    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarCursosDelEstudiante() async {
    final id = _estudianteSeleccionadoId == null ? null : int.tryParse(_estudianteSeleccionadoId!);
    if (id == null) {
      _cursoIds = {};
      return;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/').replace(
        queryParameters: {'student_id': id.toString()},
      );
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        _cursoIds = datos.map((c) => (c['id'] as int).toString()).toSet();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_misEstudiantes.isEmpty) {
      return const Center(
        child: Text('No se encontró un estudiante vinculado a tu cuenta.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListenableBuilder(
      listenable: AcademicService(),
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Horario de tu hijo/a',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                _misEstudiantes.firstWhere((s) => s.id == _estudianteSeleccionadoId).nombreCompleto,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              if (_misEstudiantes.length > 1) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _estudianteSeleccionadoId,
                  decoration: const InputDecoration(labelText: 'Estudiante', isDense: true),
                  items: _misEstudiantes
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombreCompleto)))
                      .toList(),
                  onChanged: (v) async {
                    setState(() {
                      _estudianteSeleccionadoId = v;
                      _cargando = true;
                    });
                    await _cargarCursosDelEstudiante();
                    if (mounted) setState(() => _cargando = false);
                  },
                ),
              ],
              const SizedBox(height: 20),
              Expanded(child: WeeklyScheduleGrid(entries: AcademicService().horarioPorCursos(_cursoIds))),
            ],
          ),
        );
      },
    );
  }
}
