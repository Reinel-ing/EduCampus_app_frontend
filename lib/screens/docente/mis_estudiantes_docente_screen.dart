import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../models/notificacion.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_whatsapp.dart';

class MisEstudiantesDocenteScreen extends StatelessWidget {
  const MisEstudiantesDocenteScreen({super.key});

  Future<void> _notificarRecogida(BuildContext context, Student s) async {
    if (s.acudienteTelefono.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este estudiante no tiene teléfono de acudiente registrado')),
      );
      return;
    }

    NotificationService().agregar(
      rol: RolNotificacion.acudiente,
      destinatarioId: s.id,
      titulo: 'Ya puede recoger a ${s.nombres}',
      mensaje: 'Ya puede recoger a ${s.nombreCompleto} en la institución.',
    );

    final abierto = await WhatsAppService.notificarRecogida(
      telefono: s.acudienteTelefono,
      nombreEstudiante: s.nombreCompleto,
    );

    if (context.mounted && !abierto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp. Verifica el número.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = StudentService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final students = service.students;

        if (students.isEmpty) {
          return const Center(
            child: Text(
              'Aún no hay estudiantes registrados',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final s = students[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E7EC)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    s.nombres.isNotEmpty ? s.nombres[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.grado} · Acudiente: ${s.acudienteNombre}'),
                trailing: IconButton(
                  icon: const Icon(Icons.directions_walk_rounded, color: AppColors.success),
                  tooltip: 'Notificar recogida por WhatsApp',
                  onPressed: () => _notificarRecogida(context, s),
                ),
              ),
            );
          },
        );
      },
    );
  }
}