import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/servicio_clases.dart';

class ClasesFinalizadasScreen extends StatelessWidget {
  const ClasesFinalizadasScreen({super.key});

  String _formatFechaHora(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final h = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $h';
  }

  @override
  Widget build(BuildContext context) {
    final service = ClasesService();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final clases = service.clases;
        if (clases.isEmpty) {
          return const Center(
            child: Text('Sin clases registradas', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          itemCount: clases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = clases[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E7EC)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.materia} · ${c.grado}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text(c.docenteNombre,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(_formatFechaHora(c.fechaHora),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        if (c.observacion.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(c.observacion,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}