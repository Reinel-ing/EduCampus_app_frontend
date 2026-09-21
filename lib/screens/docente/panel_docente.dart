import 'package:flutter/material.dart';
import '../../models/notificacion.dart';
import '../../widgets/estructura_app.dart';
import '../auth/pantalla_inicio_sesion.dart';
import '../comunicacion/pantalla_notificaciones.dart';
import '../evaluacion/pantalla_evaluacion_docente.dart';
import '../actividades/pantalla_actividades_docente.dart';
import '../convivencia/pantalla_convivencia_docente.dart';
import '../horario/horario_docente_screen.dart';
import '../asistencia/pantalla_asistencia.dart';
import '../materiales/pantalla_materiales.dart';
import '../calendario/pantalla_calendario.dart';
import 'contenido_inicio_docente.dart';
import 'mis_estudiantes_docente_screen.dart';

class DocenteDashboard extends StatelessWidget {
  const DocenteDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appTitle: 'EduCampus',
      roleLabel: 'Docente',
      userName: 'Docente',
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
            NavItem(label: 'Inicio', icon: Icons.home_rounded, screenBuilder: (_) => const DocenteHomeContent()),
            NavItem(label: 'Mis Estudiantes', icon: Icons.groups_2_rounded, screenBuilder: (_) => const MisEstudiantesDocenteScreen()),
          ],
        ),
        NavSection(
          title: 'Académico',
          items: [
            NavItem(label: 'Asistencia', icon: Icons.event_available_rounded, screenBuilder: (_) => const AsistenciaScreen()),
            NavItem(label: 'Calificaciones y logros', icon: Icons.grade_rounded, screenBuilder: (_) => const EvaluacionDocenteScreen()),
            NavItem(label: 'Material Didáctico', icon: Icons.folder_rounded, screenBuilder: (_) => const MaterialesScreen()),
            NavItem(label: 'Actividades', icon: Icons.assignment_rounded, screenBuilder: (_) => const ActividadesDocenteScreen()),
            NavItem(label: 'Convivencia', icon: Icons.visibility_rounded, screenBuilder: (_) => const ConvivenciaDocenteScreen()),
            NavItem(label: 'Horario', icon: Icons.schedule_rounded, screenBuilder: (_) => const HorarioDocenteScreen()),
            NavItem(label: 'Calendario', icon: Icons.calendar_month_rounded, screenBuilder: (_) => const CalendarioScreen()),
          ],
        ),
        NavSection(
          items: [
            NavItem(label: 'Notificaciones', icon: Icons.notifications_rounded, screenBuilder: (_) => const NotificacionesScreen(rol: RolNotificacion.docente)),
          ],
        ),
      ],
    );
  }
}