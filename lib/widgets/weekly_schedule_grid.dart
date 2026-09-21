import 'package:flutter/material.dart';
import '../core/theme/colores_app.dart';
import '../models/horario_entry.dart';
import '../services/academic_service.dart';

class WeeklyScheduleGrid extends StatelessWidget {
  final List<HorarioEntry> entries;
  final void Function(HorarioEntry)? onTapEntry;

  const WeeklyScheduleGrid({super.key, required this.entries, this.onTapEntry});

  @override
  Widget build(BuildContext context) {
    final service = AcademicService();

    if (entries.isEmpty) {
      return const Center(
        child: Text('Sin clases programadas', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: diasSemana.map((d) => DataColumn(label: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
        rows: [
          DataRow(
            cells: diasSemana.map((dia) {
              final entriesDelDia = entries.where((e) => e.dia == dia).toList()
                ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));

              return DataCell(
                SizedBox(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entriesDelDia.map((entry) {
                      final materia = service.materiaById(entry.materiaId);
                      return GestureDetector(
                        onTap: onTapEntry != null ? () => onTapEntry!(entry) : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (materia?.color ?? AppColors.primary).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(left: BorderSide(color: materia?.color ?? AppColors.primary, width: 3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${entry.horaInicio} - ${entry.horaFin}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(materia?.nombre ?? 'Materia eliminada', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (materia != null) Text(materia.docenteNombre, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}