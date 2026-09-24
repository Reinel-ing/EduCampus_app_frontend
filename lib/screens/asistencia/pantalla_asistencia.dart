import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colores_app.dart';
import '../../services/servicio_asistencia_backend.dart';
import '../../services/servicio_docentes.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  DateTime _fecha = DateTime.now();
  Map<int, AsistenciaDocenteBackend> _registros = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    TeacherService().cargarDesdeBackend();
    _cargarAsistencias();
  }

  String _formatearFecha(DateTime f) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${f.day} de ${meses[f.month - 1]} de ${f.year}';
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
    final url = AsistenciaBackendService().urlReporteDiario(_fecha);
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                        onPressed: () {
                          setState(() => _fecha = _fecha.add(const Duration(days: 1)));
                          _cargarAsistencias();
                        },
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _descargarReporte,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Reporte del día'),
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
