import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/academic_service.dart';
import '../../services/servicio_auth.dart';
import '../../widgets/weekly_schedule_grid.dart';

class HorarioDocenteScreen extends StatefulWidget {
  const HorarioDocenteScreen({super.key});

  @override
  State<HorarioDocenteScreen> createState() => _HorarioDocenteScreenState();
}

class _HorarioDocenteScreenState extends State<HorarioDocenteScreen> {
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    await AcademicService().cargarDesdeBackend();
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = AcademicService();
    final instructorId = AuthService().sesionActual?.usuarioId;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi horario semanal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : instructorId == null
                        ? const Center(child: Text('No se pudo identificar tu sesión.', style: TextStyle(color: AppColors.textSecondary)))
                        : WeeklyScheduleGrid(entries: service.horarioPorInstructorId(instructorId)),
              ),
            ],
          ),
        );
      },
    );
  }
}
