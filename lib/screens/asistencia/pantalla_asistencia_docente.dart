import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/colores_app.dart';
import '../../services/api_config.dart';
import '../../services/servicio_asistencia_backend.dart';
import '../../services/servicio_auth.dart';

class _CursoDocente {
  final int id;
  final String title;
  const _CursoDocente({required this.id, required this.title});
}

class _EstudianteCurso {
  final int id;
  final String nombre;
  const _EstudianteCurso({required this.id, required this.nombre});
}

const _etiquetas = {
  'presente': 'Presente',
  'ausente': 'Ausente',
  'tarde': 'Tarde',
  'excusa': 'Excusa',
};

Color _colorEstado(String? estado) {
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

class AsistenciaDocenteScreen extends StatefulWidget {
  const AsistenciaDocenteScreen({super.key});

  @override
  State<AsistenciaDocenteScreen> createState() => _AsistenciaDocenteScreenState();
}

class _AsistenciaDocenteScreenState extends State<AsistenciaDocenteScreen> {
  DateTime _fecha = DateTime.now();
  List<_CursoDocente> _cursos = [];
  int? _cursoSeleccionado;
  List<_EstudianteCurso> _estudiantes = [];
  Map<int, String> _estados = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCursos();
  }

  String _formatearFecha(DateTime f) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${f.day} de ${meses[f.month - 1]} de ${f.year}';
  }

  Future<void> _cargarCursos() async {
    final sesion = AuthService().sesionActual;
    if (sesion == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/').replace(
        queryParameters: {'instructor_id': sesion.usuarioId.toString()},
      );
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        setState(() {
          _cursos = datos
              .map((c) => _CursoDocente(id: c['id'] as int, title: c['title'] as String))
              .toList();
          _cursoSeleccionado = _cursos.isNotEmpty ? _cursos.first.id : null;
        });
        if (_cursoSeleccionado != null) await _cargarEstudiantesYAsistencia();
      }
    } catch (_) {}

    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarEstudiantesYAsistencia() async {
    if (_cursoSeleccionado == null) return;

    setState(() => _cargando = true);

    try {
      final uriMatriculas = Uri.parse('${ApiConfig.baseUrl}/cursos/$_cursoSeleccionado/estudiantes/');
      final respuesta = await http.get(uriMatriculas).timeout(const Duration(seconds: 45));

      List<_EstudianteCurso> estudiantesCurso = [];

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        estudiantesCurso = datos
            .map((e) => _EstudianteCurso(id: e['id'] as int, nombre: e['nombre'] as String))
            .toList();
      }

      final registros = await AsistenciaBackendService().listarPorCurso(
        courseId: _cursoSeleccionado!,
        fecha: _fecha,
      );

      final mapaEstados = <int, String>{
        for (final r in registros) r.studentId: r.status,
      };

      if (mounted) {
        setState(() {
          _estudiantes = estudiantesCurso;
          _estados = mapaEstados;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _marcar(int studentId, String estado) async {
    if (_cursoSeleccionado == null) return;

    setState(() => _estados[studentId] = estado);

    await AsistenciaBackendService().marcarEstudiante(
      studentId: studentId,
      courseId: _cursoSeleccionado!,
      status: estado,
      fecha: _fecha,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() => _fecha = _fecha.subtract(const Duration(days: 1)));
                      _cargarEstudiantesYAsistencia();
                    },
                  ),
                  Text(_formatearFecha(_fecha), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      setState(() => _fecha = _fecha.add(const Duration(days: 1)));
                      _cargarEstudiantesYAsistencia();
                    },
                  ),
                ],
              ),
              if (_cursos.length > 1) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _cursoSeleccionado,
                      isExpanded: true,
                      items: _cursos.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
                      onChanged: (v) {
                        setState(() => _cursoSeleccionado = v);
                        _cargarEstudiantesYAsistencia();
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _cursos.isEmpty
                  ? const Center(
                      child: Text('No tienes cursos asignados todavía.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : _estudiantes.isEmpty
                      ? const Center(
                          child: Text('No hay estudiantes matriculados en este curso.',
                              style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                          itemCount: _estudiantes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final e = _estudiantes[index];
                            final estado = _estados[e.id];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE7E7EC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: Text(
                                          e.nombre.isNotEmpty ? e.nombre[0].toUpperCase() : '?',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: _colorEstado(estado), shape: BoxShape.circle),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: ['presente', 'ausente', 'tarde', 'excusa'].map((valor) {
                                      final seleccionado = estado == valor;
                                      return ChoiceChip(
                                        label: Text(_etiquetas[valor]!),
                                        selected: seleccionado,
                                        selectedColor: _colorEstado(valor).withValues(alpha: 0.15),
                                        labelStyle: TextStyle(
                                          color: seleccionado ? _colorEstado(valor) : AppColors.textPrimary,
                                          fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        onSelected: (_) => _marcar(e.id, valor),
                                      );
                                    }).toList(),
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
