import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../services/servicio_alertas.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_estudiantes.dart';

class AcudienteHomeContent extends StatelessWidget {
  const AcudienteHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final estSvc = StudentService();
    final alertaSvc = AlertasService();

    estSvc.cargarDesdeBackendSiHaceFalta();
    alertaSvc.cargarDesdeBackendSiHaceFalta();

    return ListenableBuilder(
      listenable: Listenable.merge([estSvc, alertaSvc]),
      builder: (context, _) {
        final sesion = AuthService().sesionActual;
        final correo = sesion?.correo;

        // Estudiantes vinculados a esta cuenta (por correo del acudiente)
        final misEstudiantes = correo == null
            ? <Student>[]
            : estSvc.students
                .where((s) => s.acudienteCorreo.trim().toLowerCase() == correo)
                .toList();
        final tieneCuenta = correo != null;

        // Alertas de mis estudiantes
        final misAlertas = misEstudiantes.isEmpty
            ? []
            : alertaSvc.alertas
                .where((a) =>
                    misEstudiantes.any((s) => s.id == a.estudianteId) &&
                    !a.atendida)
                .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink.shade600,
                      Colors.pink.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.family_restroom_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sesion != null
                                ? 'Bienvenido/a, ${sesion.nombre}'
                                : 'Portal del Acudiente',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'COLMAS — Seguimiento académico',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Alerta si hay notificaciones ──
              if (misAlertas.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tienes ${misAlertas.length} alerta(s) sin atender de tu(s) hijo(s).',
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Mis estudiantes ──
              _SeccionHeader(
                titulo: 'Mi(s) estudiante(s)',
                badge: misEstudiantes.length,
                color: Colors.pink.shade600,
              ),
              const SizedBox(height: 12),

              if (misEstudiantes.isEmpty)
                _EmptyCard(
                  icon: Icons.person_search_rounded,
                  mensaje: !tieneCuenta
                      ? 'No se encontró tu cuenta.\nContacta al administrador.'
                      : 'No tienes estudiantes vinculados aún.\nContacta al administrador para vincular a tu hijo/a.',
                )
              else
                ...misEstudiantes.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaEstudiante(
                        estudiante: s,
                        tieneAlertas: misAlertas
                            .any((a) => a.estudianteId == s.id),
                      ),
                    )),

              const SizedBox(height: 20),

              // ── Seguimiento académico ──
              _SeccionHeader(
                titulo: 'Seguimiento académico',
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),

              GridView.extent(
                maxCrossAxisExtent: 160,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: const [
                  _SeguimientoItem(
                      icon: Icons.grade_rounded,
                      label: 'Calificaciones',
                      color: Colors.deepPurple),
                  _SeguimientoItem(
                      icon: Icons.event_available_rounded,
                      label: 'Asistencia',
                      color: Colors.teal),
                  _SeguimientoItem(
                      icon: Icons.assignment_rounded,
                      label: 'Actividades',
                      color: Colors.orange),
                  _SeguimientoItem(
                      icon: Icons.folder_rounded,
                      label: 'Materiales',
                      color: Colors.blue),
                  _SeguimientoItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Calendario',
                      color: Colors.green),
                  _SeguimientoItem(
                      icon: Icons.campaign_rounded,
                      label: 'Comunicados',
                      color: Colors.pink),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Widgets privados ─────────────────────────────
class _SeccionHeader extends StatelessWidget {
  final String titulo;
  final int? badge;
  final Color color;
  const _SeccionHeader({required this.titulo, this.badge, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$badge',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _TarjetaEstudiante extends StatelessWidget {
  final Student estudiante;
  final bool tieneAlertas;
  const _TarjetaEstudiante(
      {required this.estudiante, this.tieneAlertas = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7EC)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              estudiante.nombreCompleto.isNotEmpty
                  ? estudiante.nombreCompleto[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estudiante.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.school_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      estudiante.grado,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (tieneAlertas)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 20),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: ${estudiante.id}',
              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String mensaje;
  const _EmptyCard({required this.icon, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _SeguimientoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SeguimientoItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}