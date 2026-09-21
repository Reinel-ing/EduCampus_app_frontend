import 'package:educampus_app/widgets/pantalla_formulario_estudiantes.dart';
import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../models/notificacion.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_whatsapp.dart';

class EstudiantesListScreen extends StatefulWidget {
  const EstudiantesListScreen({super.key});

  @override
  State<EstudiantesListScreen> createState() => _EstudiantesListScreenState();
}

class _EstudiantesListScreenState extends State<EstudiantesListScreen> {
  @override
  void initState() {
    super.initState();
    StudentService().cargarDesdeBackend();
  }

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

    return Stack(
      children: [
        ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final students = service.students;

            if (students.isEmpty) {
              return Center(
                child: Text(
                  service.cargando ? 'Cargando estudiantes...' : 'Aún no hay estudiantes registrados',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.directions_walk_rounded, color: AppColors.success),
                          tooltip: 'Notificar recogida por WhatsApp',
                          onPressed: () => _notificarRecogida(context, s),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormularioEstudianteScreen(estudiante: s),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FormularioEstudianteScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar'),
          ),
        ),
      ],
    );
  }
}