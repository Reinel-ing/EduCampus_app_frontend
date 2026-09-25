import 'package:educampus_app/widgets/pantalla_formulario_estudiantes.dart';
import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_notificaciones_backend.dart';
import '../../services/servicio_whatsapp.dart';

class EstudiantesListScreen extends StatefulWidget {
  const EstudiantesListScreen({super.key});

  @override
  State<EstudiantesListScreen> createState() => _EstudiantesListScreenState();
}

class _EstudiantesListScreenState extends State<EstudiantesListScreen> {
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    StudentService().cargarDesdeBackend();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _notificarRecogida(BuildContext context, Student s) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Avisar a ${s.acudienteNombre.isNotEmpty ? s.acudienteNombre : "el acudiente"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debe pasar a recoger a ${s.nombreCompleto}. Explica por qué:'),
            const SizedBox(height: 12),
            TextField(
              controller: motivoController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: El estudiante se siente mal del estómago...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, motivoController.text.trim());
            },
            child: const Text('Enviar aviso'),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.isEmpty) return;

    try {
      await NotificacionesBackendService().crearAlerta(
        studentId: int.parse(s.id),
        mensaje: motivo,
        severidad: 'alta',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aviso enviado a ${s.acudienteNombre.isNotEmpty ? s.acudienteNombre : "el acudiente"}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el aviso. Intenta de nuevo.')),
        );
      }
      return;
    }

    if (s.acudienteTelefono.trim().isNotEmpty) {
      await WhatsAppService.enviarMensaje(
        telefono: s.acudienteTelefono,
        mensaje: 'Hola, le informamos desde COLMAS que debe pasar a recoger a '
            '${s.nombreCompleto}. Motivo: $motivo',
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
            final todos = service.students;
            final filtro = _busqueda.trim().toLowerCase();
            final students = filtro.isEmpty
                ? todos
                : todos.where((s) => s.nombreCompleto.toLowerCase().contains(filtro)).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: TextField(
                    controller: _busquedaCtrl,
                    onChanged: (v) => setState(() => _busqueda = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _busqueda.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() {
                                _busquedaCtrl.clear();
                                _busqueda = '';
                              }),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E7EC))),
                    ),
                  ),
                ),
                Expanded(
                  child: todos.isEmpty
                      ? Center(
                          child: Text(
                            service.cargando ? 'Cargando estudiantes...' : 'Aún no hay estudiantes registrados',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : students.isEmpty
                          ? const Center(
                              child: Text('No se encontró ningún estudiante con ese nombre',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
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
                            ),
                ),
              ],
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