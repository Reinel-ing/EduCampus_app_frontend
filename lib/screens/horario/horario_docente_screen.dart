import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/academic_service.dart';
import '../../widgets/weekly_schedule_grid.dart';

class HorarioDocenteScreen extends StatefulWidget {
  const HorarioDocenteScreen({super.key});

  @override
  State<HorarioDocenteScreen> createState() => _HorarioDocenteScreenState();
}

class _HorarioDocenteScreenState extends State<HorarioDocenteScreen> {
  final _nombreCtrl = TextEditingController();
  String? _docenteActivo;

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
              const Text('Mi horario semanal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Tu nombre (como docente registrado)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => setState(() => _docenteActivo = _nombreCtrl.text.trim()),
                    child: const Text('Ver horario'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _docenteActivo == null || _docenteActivo!.isEmpty
                    ? const Center(child: Text('Escribe tu nombre para ver tu horario', style: TextStyle(color: AppColors.textSecondary)))
                    : WeeklyScheduleGrid(entries: service.horarioPorDocente(_docenteActivo!)),
              ),
            ],
          ),
        );
      },
    );
  }
}