import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/alerta_alumno.dart';
import '../../models/clase_finalizada.dart';
import '../../models/notificacion.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_docentes.dart';
import '../../services/servicio_alertas.dart';
import '../../services/servicio_clases.dart';
import '../../services/servicio_acudientes.dart';
import '../../services/servicio_grados.dart';
import '../comunicacion/pantalla_notificaciones.dart';
import 'pantalla_alertas_alumnos.dart';
import 'pantalla_gestion_acudientes.dart';
import 'pantalla_gestion_docentes.dart';

class AdminHomeContent extends StatelessWidget {
  const AdminHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final studentService = StudentService();
    final teacherService = TeacherService();
    final alertasService = AlertasService();
    final clasesService = ClasesService();
    final acudientesService = AcudientesService();
    final gradoService = GradoService();

    return ListenableBuilder(
      listenable: Listenable.merge([
        studentService,
        teacherService,
        alertasService,
        clasesService,
        acudientesService,
      ]),
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner admin
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text('Panel de Administración',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Bienvenido, Administrador',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Colegio Manantial de Sabiduría · COLMAS',
                        style:
                            TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tarjetas de estadísticas
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 4 : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: isWide ? 1.4 : 1.1,
                    children: [
                      _AdminStatCard(
                        icon: Icons.groups_2_rounded,
                        label: 'Estudiantes',
                        value: '${studentService.students.length}',
                        color: AppColors.primary,
                      ),
                      _AdminStatCard(
                        icon: Icons.badge_rounded,
                        label: 'Docentes',
                        value: '${teacherService.teachers.length}',
                        color: Colors.blue.shade600,
                      ),
                      _AdminStatCard(
                        icon: Icons.family_restroom_rounded,
                        label: 'Acudientes',
                        value: '${acudientesService.cuentas.length}',
                        color: Colors.pink.shade400,
                      ),
                      _AdminStatCard(
                        icon: Icons.class_rounded,
                        label: 'Grados',
                        value: '${gradoService.grados.length}',
                        color: Colors.orange.shade700,
                      ),
                    ],
                  );
                },
              ),

              // Alertas pendientes
              if (alertasService.pendientes.isNotEmpty) ...[
                const SizedBox(height: 24),
                _AdminSectionHeader(
                  icon: Icons.warning_amber_rounded,
                  title: 'Alertas pendientes de alumnos',
                  color: AppColors.danger,
                  badge: alertasService.pendientes.length,
                ),
                const SizedBox(height: 10),
                ...alertasService.pendientes.take(3).map((a) => _AdminAlertaCard(alerta: a)),
              ],

              // Clases finalizadas recientes
              if (clasesService.noVistas.isNotEmpty) ...[
                const SizedBox(height: 24),
                _AdminSectionHeader(
                  icon: Icons.flag_rounded,
                  title: 'Clases finalizadas recientes',
                  color: AppColors.accent,
                  badge: clasesService.noVistas.length,
                ),
                const SizedBox(height: 10),
                ...clasesService.noVistas.take(3).map((c) => _AdminClaseCard(clase: c)),
              ],

              // Resumen del sistema
              const SizedBox(height: 24),
              const _AdminSectionHeader(
                icon: Icons.bar_chart_rounded,
                title: 'Resumen del sistema',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7E7EC)),
                ),
                child: Column(
                  children: [
                    _ResumenFila(
                      label: 'Total alertas generadas',
                      value: '${alertasService.alertas.length}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.danger,
                    ),
                    const Divider(height: 20),
                    _ResumenFila(
                      label: 'Total clases finalizadas',
                      value: '${clasesService.clases.length}',
                      icon: Icons.flag_rounded,
                      color: AppColors.accent,
                    ),
                    const Divider(height: 20),
                    _ResumenFila(
                      label: 'Alertas atendidas',
                      value:
                          '${alertasService.alertas.where((a) => a.atendida).length}',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),

              // Accesos rápidos
              const SizedBox(height: 24),
              const _AdminSectionHeader(
                icon: Icons.rocket_launch_rounded,
                title: 'Accesos rápidos',
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AdminQuickButton(
                    icon: Icons.person_add_rounded,
                    label: 'Registrar docente',
                    color: Colors.blue.shade600,
                    onTap: () => _abrirPantalla(
                      context,
                      titulo: 'Docentes',
                      child: const GestionDocentesScreen(),
                    ),
                  ),
                  _AdminQuickButton(
                    icon: Icons.group_add_rounded,
                    label: 'Registrar acudiente',
                    color: Colors.pink.shade400,
                    onTap: () => _abrirPantalla(
                      context,
                      titulo: 'Acudientes',
                      child: const GestionAcudientesScreen(),
                    ),
                  ),
                  _AdminQuickButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Ver alertas',
                    color: AppColors.danger,
                    onTap: () => _abrirPantalla(
                      context,
                      titulo: 'Alertas de alumnos',
                      child: const AlertasAlumnosScreen(),
                    ),
                  ),
                  _AdminQuickButton(
                    icon: Icons.campaign_rounded,
                    label: 'Enviar comunicado',
                    color: AppColors.accent,
                    onTap: () => _abrirPantalla(
                      context,
                      titulo: 'Comunicación',
                      child: const NotificacionesScreen(rol: RolNotificacion.admin),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

void _abrirPantalla(
  BuildContext context, {
  required String titulo,
  required Widget child,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: child,
      ),
    ),
  );
}

class _AdminSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int? badge;

  const _AdminSectionHeader(
      {required this.icon, required this.title, required this.color, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
        ),
        if (badge != null && badge! > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$badge',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AdminStatCard(
      {required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          Text(label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AdminAlertaCard extends StatelessWidget {
  final AlertaAlumno alerta;
  const _AdminAlertaCard({required this.alerta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.danger.withOpacity(0.1),
            child: const Icon(Icons.person_rounded, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alerta.estudianteNombre,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(alerta.descripcion,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _AdminClaseCard extends StatelessWidget {
  final ClaseFinalizada clase;
  const _AdminClaseCard({required this.clase});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withOpacity(0.1),
            child: const Icon(Icons.flag_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${clase.materia} · ${clase.grado}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Docente: ${clase.docenteNombre}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${clase.fechaHora.hour.toString().padLeft(2, '0')}:${clase.fechaHora.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ResumenFila extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ResumenFila(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _AdminQuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AdminQuickButton(
      {required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}