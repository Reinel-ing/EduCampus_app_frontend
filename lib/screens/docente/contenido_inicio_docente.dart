import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/alerta_alumno.dart';
import '../../models/clase_finalizada.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_alertas.dart';
import '../../services/servicio_clases.dart';
import '../../services/servicio_materiales.dart';

class DocenteHomeContent extends StatelessWidget {
  const DocenteHomeContent({super.key});

  String _formatFecha(DateTime dt) {
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return '${dias[dt.weekday - 1]} ${dt.day} de ${meses[dt.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final studentService = StudentService();
    final alertasService = AlertasService();
    final clasesService = ClasesService();
    final materialService = MaterialService();
    final hoy = DateTime.now();

    return ListenableBuilder(
      listenable: Listenable.merge([studentService, alertasService, clasesService, materialService]),
      builder: (context, _) {
        final clasesHoy = clasesService.clases
            .where((c) =>
                c.fechaHora.day == hoy.day &&
                c.fechaHora.month == hoy.month &&
                c.fechaHora.year == hoy.year)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.badge_rounded, color: Colors.white70, size: 18),
                              SizedBox(width: 6),
                              Text('Panel del Docente',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Bienvenido, Docente',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Colegio Manantial de Sabiduría · COLMAS',
                              style:
                                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text('${hoy.day}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          Text(_formatFecha(hoy),
                              style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Acciones rápidas
              const _DHeader(
                  title: 'Mis acciones de hoy',
                  icon: Icons.flash_on_rounded,
                  color: Colors.amber),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AccionCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Finalizar\nclase',
                      color: AppColors.accent,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AccionCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'Generar\nalerta',
                      color: AppColors.danger,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AccionCard(
                      icon: Icons.event_available_rounded,
                      label: 'Tomar\nasistencia',
                      color: AppColors.success,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AccionCard(
                      icon: Icons.upload_file_rounded,
                      label: 'Subir\nmaterial',
                      color: Colors.teal.shade600,
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Resumen rápido
              Row(
                children: [
                  Expanded(
                    child: _ResumenChip(
                      icon: Icons.groups_2_rounded,
                      label: 'Estudiantes',
                      value: '${studentService.students.length}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResumenChip(
                      icon: Icons.flag_rounded,
                      label: 'Clases hoy',
                      value: '${clasesHoy.length}',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResumenChip(
                      icon: Icons.folder_rounded,
                      label: 'Materiales',
                      value: '${materialService.materiales.length}',
                      color: Colors.teal.shade600,
                    ),
                  ),
                ],
              ),

              // Clases de hoy
              if (clasesHoy.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _DHeader(
                    title: 'Clases finalizadas hoy',
                    icon: Icons.today_rounded,
                    color: AppColors.accent),
                const SizedBox(height: 10),
                ...clasesHoy.map((c) => _ClaseCard(clase: c)),
              ],

              // Últimas clases si no hay hoy
              if (clasesHoy.isEmpty && clasesService.clases.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _DHeader(
                    title: 'Últimas clases registradas',
                    icon: Icons.history_rounded,
                    color: AppColors.accent),
                const SizedBox(height: 10),
                ...clasesService.clases.take(3).map((c) => _ClaseCard(clase: c)),
              ],

              // Alertas pendientes
              if (alertasService.pendientes.isNotEmpty) ...[
                const SizedBox(height: 24),
                _DHeader(
                    title: 'Alertas sin atender (${alertasService.pendientes.length})',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger),
                const SizedBox(height: 10),
                ...alertasService.pendientes.take(3).map((a) => _AlertaCard(alerta: a)),
              ],

              // Estado vacío
              if (clasesService.clases.isEmpty && alertasService.pendientes.isEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7E7EC)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.school_rounded, size: 48, color: Colors.blue.shade200),
                      const SizedBox(height: 12),
                      const Text('Todo al día',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('No hay clases ni alertas pendientes por ahora.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _DHeader({required this.title, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccionCard(
      {required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ResumenChip(
      {required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaseCard extends StatelessWidget {
  final ClaseFinalizada clase;
  const _ClaseCard({required this.clase});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${clase.materia} · ${clase.grado}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (clase.observacion.isNotEmpty)
                  Text(clase.observacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${clase.fechaHora.hour.toString().padLeft(2, '0')}:${clase.fechaHora.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final AlertaAlumno alerta;
  const _AlertaCard({required this.alerta});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alerta.estudianteNombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${alerta.grado} · ${alerta.descripcion}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(alerta.nivel.etiqueta,
                style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}