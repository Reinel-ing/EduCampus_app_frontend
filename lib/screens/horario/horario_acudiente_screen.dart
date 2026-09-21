import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/academic_service.dart';
import '../../services/servicio_grados.dart';
import '../../widgets/weekly_schedule_grid.dart';

class HorarioAcudienteScreen extends StatefulWidget {
  const HorarioAcudienteScreen({super.key});

  @override
  State<HorarioAcudienteScreen> createState() => _HorarioAcudienteScreenState();
}

class _HorarioAcudienteScreenState extends State<HorarioAcudienteScreen> {
  String _gradoSeleccionado = GradoService().grados.first;

  @override
  Widget build(BuildContext context) {
    final service = AcademicService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Horario del grado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gradoSeleccionado,
                decoration: const InputDecoration(labelText: 'Grado de tu hijo/a', isDense: true),
                items: GradoService().grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gradoSeleccionado = v ?? _gradoSeleccionado),
              ),
              const SizedBox(height: 20),
              Expanded(child: WeeklyScheduleGrid(entries: service.horarioPorGrado(_gradoSeleccionado))),
            ],
          ),
        );
      },
    );
  }
}