import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colores_app.dart';
import '../../services/api_config.dart';
import '../../services/servicio_asistencia_backend.dart';
import '../../services/servicio_docentes.dart';
import '../../services/servicio_grados.dart';

class _Curso {
  final int id;
  final String title;
  final int? gradoId;
  const _Curso({required this.id, required this.title, this.gradoId});
}

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  DateTime _fecha = DateTime.now();
  Map<int, AsistenciaDocenteBackend> _registros = {};
  bool _cargando = true;
  List<_Curso> _cursos = [];

  @override
  void initState() {
    super.initState();
    TeacherService().cargarDesdeBackend();
    GradoService().cargarDesdeBackend();
    _cargarAsistencias();
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        if (!mounted) return;
        setState(() {
          _cursos = datos
              .map((c) => _Curso(
                    id: c['id'] as int,
                    title: c['title'] as String,
                    gradoId: c['grado_id'] as int?,
                  ))
              .toList();
        });
      }
    } catch (_) {}
  }

  String _formatearFecha(DateTime f) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${f.day} de ${meses[f.month - 1]} de ${f.year}';
  }

  bool get _esHoy {
    final hoy = DateTime.now();
    return _fecha.year == hoy.year && _fecha.month == hoy.month && _fecha.day == hoy.day;
  }

  Future<void> _cargarAsistencias() async {
    setState(() => _cargando = true);
    final lista = await AsistenciaBackendService().listarDocentes(_fecha);
    if (!mounted) return;
    setState(() {
      _registros = {for (final r in lista) r.profesorId: r};
      _cargando = false;
    });
  }

  Future<void> _marcar(int profesorId, {bool? presente, bool? completo}) async {
    final actual = _registros[profesorId];
    final nuevoPresente = presente ?? actual?.presente ?? true;
    final nuevoCompleto = completo ?? actual?.completo ?? true;

    setState(() {
      _registros[profesorId] = AsistenciaDocenteBackend(
        profesorId: profesorId,
        fecha: formatearFechaISO(_fecha),
        presente: nuevoPresente,
        completo: nuevoCompleto,
      );
    });

    await AsistenciaBackendService().marcarDocente(
      profesorId: profesorId,
      fecha: _fecha,
      presente: nuevoPresente,
      completo: nuevoCompleto,
    );
  }

  Future<void> _descargarReporte() async {
    final gradoService = GradoService();

    if (gradoService.grados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay grados registrados todavía.')),
      );
      return;
    }

    String? gradoElegido;
    _Curso? cursoElegido;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final gradoId = gradoElegido == null ? null : gradoService.idPorNombre(gradoElegido!);
          final cursosDelGrado = gradoId == null
              ? <_Curso>[]
              : _cursos.where((c) => c.gradoId == gradoId).toList();

          return AlertDialog(
            title: const Text('Reporte de asistencia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GRADO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: gradoElegido,
                  hint: const Text('Selecciona un grado'),
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: gradoService.grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setDialogState(() {
                    gradoElegido = v;
                    cursoElegido = null;
                  }),
                ),
                const SizedBox(height: 16),
                const Text('MATERIA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<_Curso>(
                  initialValue: cursoElegido,
                  hint: Text(gradoElegido == null ? 'Elige un grado primero' : 'Selecciona una materia'),
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: cursosDelGrado
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.title)))
                      .toList(),
                  onChanged: cursosDelGrado.isEmpty ? null : (v) => setDialogState(() => cursoElegido = v),
                ),
                if (gradoElegido != null && cursosDelGrado.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Este grado no tiene materias registradas.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: cursoElegido == null
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        final url = AsistenciaBackendService().urlReporteDiario(
                          cursoId: cursoElegido!.id,
                          fecha: _fecha,
                        );
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                child: const Text('Descargar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherService = TeacherService();

    return ListenableBuilder(
      listenable: teacherService,
      builder: (context, _) {
        final docentes = teacherService.teachers;

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
                          _cargarAsistencias();
                        },
                      ),
                      Text(_formatearFecha(_fecha), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _esHoy
                            ? null
                            : () {
                                setState(() => _fecha = _fecha.add(const Duration(days: 1)));
                                _cargarAsistencias();
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _descargarReporte,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Descargar reporte por grado y materia'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : docentes.isEmpty
                      ? const Center(
                          child: Text('Aún no hay docentes registrados',
                              style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                          itemCount: docentes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final d = docentes[index];
                            final id = int.tryParse(d.id);
                            final registro = id != null ? _registros[id] : null;

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
                                        backgroundColor: Colors.blue.shade50,
                                        child: Text(
                                          d.nombres.isNotEmpty ? d.nombres[0].toUpperCase() : '?',
                                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(d.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text(d.especialidad,
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: registro == null
                                              ? const Color(0xFFB0B0B8)
                                              : (registro.presente ? AppColors.success : AppColors.danger),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (id != null) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ChoiceChip(
                                          label: const Text('Presente'),
                                          selected: registro?.presente == true,
                                          selectedColor: AppColors.success.withValues(alpha: 0.15),
                                          onSelected: (_) => _marcar(id, presente: true),
                                        ),
                                        ChoiceChip(
                                          label: const Text('Ausente'),
                                          selected: registro?.presente == false,
                                          selectedColor: AppColors.danger.withValues(alpha: 0.15),
                                          onSelected: (_) => _marcar(id, presente: false),
                                        ),
                                        if (registro?.presente ?? true) ...[
                                          const SizedBox(width: 12),
                                          FilterChip(
                                            label: const Text('Cumplió todo'),
                                            selected: registro?.completo ?? true,
                                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                                            onSelected: (v) => _marcar(id, presente: true, completo: v),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
