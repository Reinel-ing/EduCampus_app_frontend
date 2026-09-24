import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../services/api_config.dart';
import '../../services/servicio_asistencia_backend.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_estudiantes.dart';

const _etiquetas = {
  'presente': 'Presente',
  'ausente': 'Ausente',
  'tarde': 'Tarde',
  'excusa': 'Excusa',
};

Color _colorEstado(String estado) {
  switch (estado) {
    case 'presente':
      return AppColors.success;
    case 'tarde':
      return AppColors.accent;
    case 'ausente':
      return AppColors.danger;
    case 'excusa':
      return AppColors.textSecondary;
    default:
      return const Color(0xFFB0B0B8);
  }
}

class AsistenciaAcudienteScreen extends StatefulWidget {
  const AsistenciaAcudienteScreen({super.key});

  @override
  State<AsistenciaAcudienteScreen> createState() => _AsistenciaAcudienteScreenState();
}

class _AsistenciaAcudienteScreenState extends State<AsistenciaAcudienteScreen> {
  bool _cargando = true;
  List<Student> _misEstudiantes = [];
  String? _estudianteSeleccionadoId;
  List<AsistenciaEstudianteBackend> _registros = [];
  Map<int, String> _cursos = {};

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

    _misEstudiantes = StudentService()
        .students
        .where((s) => s.acudienteCorreo.trim().toLowerCase() == correo)
        .toList();

    _estudianteSeleccionadoId = _misEstudiantes.isNotEmpty ? _misEstudiantes.first.id : null;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        _cursos = {for (final c in datos) c['id'] as int: c['title'] as String};
      }
    } catch (_) {}

    await _cargarAsistencia();

    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarAsistencia() async {
    final id = _estudianteSeleccionadoId == null ? null : int.tryParse(_estudianteSeleccionadoId!);
    if (id == null) {
      _registros = [];
      return;
    }
    final hoy = DateTime.now();
    final registros = await AsistenciaBackendService().listarPorEstudiante(id);
    _registros = registros.where((r) {
      final fecha = DateTime.tryParse(r.fecha);
      return fecha == null || !fecha.isAfter(DateTime(hoy.year, hoy.month, hoy.day));
    }).toList();
  }

  String _formatearFecha(String isoFecha) {
    final f = DateTime.tryParse(isoFecha);
    if (f == null) return isoFecha;
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${f.day} de ${meses[f.month - 1]} de ${f.year}';
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

    return Column(
      children: [
        if (_misEstudiantes.length > 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _estudianteSeleccionadoId,
                  isExpanded: true,
                  items: _misEstudiantes
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombreCompleto)))
                      .toList(),
                  onChanged: (v) async {
                    setState(() {
                      _estudianteSeleccionadoId = v;
                      _cargando = true;
                    });
                    await _cargarAsistencia();
                    if (mounted) setState(() => _cargando = false);
                  },
                ),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.white,
          child: Text(
            _misEstudiantes
                .firstWhere((s) => s.id == _estudianteSeleccionadoId, orElse: () => _misEstudiantes.first)
                .nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Expanded(
          child: _registros.isEmpty
              ? const Center(
                  child: Text('Aún no hay asistencia registrada.',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  itemCount: _registros.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = _registros[index];
                    final color = _colorEstado(r.status);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE7E7EC)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatearFecha(r.fecha), style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  _cursos[r.courseId] ?? 'Curso',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _etiquetas[r.status] ?? r.status,
                              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
