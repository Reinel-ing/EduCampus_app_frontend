import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/asistencia.dart';
import '../../services/servicio_asistencia.dart';
import '../../services/servicio_estudiantes.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  DateTime _fecha = DateTime.now();

  String _formatearFecha(DateTime f) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${f.day} de ${meses[f.month - 1]} de ${f.year}';
  }

  Color _colorEstado(EstadoAsistencia? estado) {
    switch (estado) {
      case EstadoAsistencia.presente:
        return AppColors.success;
      case EstadoAsistencia.tarde:
        return AppColors.accent;
      case EstadoAsistencia.ausente:
        return AppColors.danger;
      case EstadoAsistencia.excusa:
        return AppColors.textSecondary;
      case null:
        return const Color(0xFFB0B0B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estudiantesService = StudentService();
    final asistenciaService = AsistenciaService();

    return ListenableBuilder(
      listenable: Listenable.merge([estudiantesService, asistenciaService]),
      builder: (context, _) {
        final estudiantes = estudiantesService.students;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _fecha = _fecha.subtract(const Duration(days: 1))),
                  ),
                  Text(_formatearFecha(_fecha), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(() => _fecha = _fecha.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: estudiantes.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no hay estudiantes registrados',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      itemCount: estudiantes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = estudiantes[index];
                        final estado = asistenciaService.estadoDe(s.id, _fecha);

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
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: Text(
                                      s.nombres.isNotEmpty ? s.nombres[0].toUpperCase() : '?',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(s.grado, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                      ],
                                    ),
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
                                children: EstadoAsistencia.values.map((e) {
                                  final seleccionado = estado == e;
                                  return ChoiceChip(
                                    label: Text(e.etiqueta),
                                    selected: seleccionado,
                                    selectedColor: _colorEstado(e).withOpacity(0.15),
                                    labelStyle: TextStyle(
                                      color: seleccionado ? _colorEstado(e) : AppColors.textPrimary,
                                      fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    onSelected: (_) {
                                      asistenciaService.marcar(estudianteId: s.id, fecha: _fecha, estado: e);
                                    },
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
      },
    );
  }
}