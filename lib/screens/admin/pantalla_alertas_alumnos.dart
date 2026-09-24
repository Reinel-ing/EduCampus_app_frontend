import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/alerta_alumno.dart';
import '../../services/servicio_alertas.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_whatsapp.dart';

class AlertasAlumnosScreen extends StatelessWidget {
  const AlertasAlumnosScreen({super.key});

  Color _colorNivel(NivelAlerta nivel) {
    switch (nivel) {
      case NivelAlerta.informativo:
        return Colors.blue.shade600;
      case NivelAlerta.seguimiento:
        return Colors.orange.shade700;
      case NivelAlerta.urgente:
        return AppColors.danger;
    }
  }

  void _atenderAlerta(BuildContext context, AlertaAlumno alerta) async {
    final respCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atender alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estudiante: ${alerta.estudianteNombre}'),
            Text('Grado: ${alerta.grado}'),
            const SizedBox(height: 8),
            Text('Descripción: ${alerta.descripcion}'),
            const SizedBox(height: 16),
            TextField(
              controller: respCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Respuesta / acción tomada',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Marcar atendida')),
        ],
      ),
    );
    if (confirmado == true) {
      final messenger = ScaffoldMessenger.of(context);
      final error = await AlertasService().atender(alerta.id, respuesta: respCtrl.text.trim());
      if (error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _notificarAcudiente(BuildContext context, AlertaAlumno alerta) {
    final coincidencias = StudentService().students.where((s) => s.id == alerta.estudianteId).toList();
    if (coincidencias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante no encontrado en el sistema')),
      );
      return;
    }
    final estudiante = coincidencias.first;
    if (estudiante.acudienteTelefono.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este estudiante no tiene teléfono de acudiente registrado')),
      );
      return;
    }
    WhatsAppService.notificarRecogida(
      telefono: estudiante.acudienteTelefono,
      nombreEstudiante: estudiante.nombreCompleto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AlertasService();
    service.cargarDesdeBackendSiHaceFalta();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final alertas = service.alertas;
        if (alertas.isEmpty) {
          return const Center(
            child: Text('Sin alertas registradas', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          itemCount: alertas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final a = alertas[index];
            final color = _colorNivel(a.nivel);
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: a.atendida ? const Color(0xFFE7E7EC) : color.withOpacity(0.4)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(Icons.warning_amber_rounded, color: color, size: 20),
                ),
                title: Text(
                  a.estudianteNombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: a.atendida ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: a.atendida ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text('${a.nivel.etiqueta} · ${a.grado} · ${a.docenteNombre}'),
                trailing: a.atendida
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.directions_walk_rounded, color: AppColors.success),
                            tooltip: 'Notificar acudiente',
                            onPressed: () => _notificarAcudiente(context, a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
                            tooltip: 'Atender alerta',
                            onPressed: () => _atenderAlerta(context, a),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}