import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/notificacion.dart';
import '../../services/servicio_notificaciones.dart';

class NotificacionesScreen extends StatelessWidget {
  final RolNotificacion rol;
  const NotificacionesScreen({super.key, required this.rol});

  IconData _iconoPara(String titulo) {
    final t = titulo.toLowerCase();
    if (t.contains('recoger') || t.contains('recogida')) return Icons.directions_walk_rounded;
    if (t.contains('clase')) return Icons.school_rounded;
    return Icons.campaign_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final lista = service.paraRol(rol);

        if (lista.isEmpty) {
          return const Center(
            child: Text('No hay notificaciones por ahora', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final n = lista[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: n.leida ? const Color(0xFFE7E7EC) : AppColors.primary.withOpacity(0.4),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(_iconoPara(n.titulo), color: AppColors.primary),
                ),
                title: Text(n.titulo, style: TextStyle(fontWeight: n.leida ? FontWeight.w500 : FontWeight.bold)),
                subtitle: Text(n.mensaje),
                trailing: Text(
                  '${n.fecha.hour.toString().padLeft(2, '0')}:${n.fecha.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                onTap: () => service.marcarLeida(n.id),
              ),
            );
          },
        );
      },
    );
  }
}