import 'package:flutter/material.dart';
import '../../models/notificacion.dart';
import '../../widgets/estructura_app.dart';
import '../auth/pantalla_inicio_sesion.dart';
import '../comunicacion/pantalla_notificaciones.dart';
import 'contenido_inicio_acudiente.dart';
import 'pantalla_actividades_acudiente.dart';
import '../horario/horario_acudiente_screen.dart';
import '../evaluacion/pantalla_evaluacion_docente.dart';
import '../asistencia/pantalla_asistencia_acudiente.dart';
import '../materiales/pantalla_materiales.dart';
import '../calendario/pantalla_calendario.dart';

class AcudienteDashboard extends StatelessWidget {
  const AcudienteDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appTitle: 'EduCampus',
      roleLabel: 'Acudiente',
      userName: 'Acudiente',
      onLogout: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      sections: [
        NavSection(
          title: 'Principal',
          items: [
            NavItem(label: 'Inicio', icon: Icons.home_rounded, screenBuilder: (_) => const AcudienteHomeContent()),
          ],
        ),
        NavSection(
          title: 'Seguimiento',
          items: [
            NavItem(label: 'Actividades y entregas', icon: Icons.assignment_rounded, screenBuilder: (_) => const ActividadesAcudienteScreen()),
            NavItem(label: 'Calificaciones y logros', icon: Icons.grade_rounded, screenBuilder: (_) => const EvaluacionDocenteScreen()),
            NavItem(label: 'Asistencia', icon: Icons.event_available_rounded, screenBuilder: (_) => const AsistenciaAcudienteScreen()),
            NavItem(label: 'Materiales', icon: Icons.folder_rounded, screenBuilder: (_) => const MaterialesScreen()),
            NavItem(label: 'Horario', icon: Icons.schedule_rounded, screenBuilder: (_) => const HorarioAcudienteScreen()),
            NavItem(label: 'Calendario', icon: Icons.calendar_month_rounded, screenBuilder: (_) => const CalendarioScreen()),
          ],
        ),
        NavSection(
          items: [
            NavItem(label: 'Notificaciones', icon: Icons.notifications_rounded, screenBuilder: (_) => const NotificacionesScreen(rol: RolNotificacion.acudiente)),
          ],
        ),
      ],
    );
  }
}