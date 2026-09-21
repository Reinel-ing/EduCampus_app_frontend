import 'package:flutter/material.dart';
import '../../models/notificacion.dart';
import '../../widgets/estructura_app.dart';
import '../auth/pantalla_inicio_sesion.dart';
import '../comunicacion/pantalla_notificaciones.dart';
import '../estudiantes/pantalla_lista_estudiantes.dart';
import '../evaluacion/pantalla_evaluacion_docente.dart';
import '../convivencia/pantalla_convivencia_docente.dart';
import '../grados/pantalla_grados.dart';
import '../asistencia/pantalla_asistencia.dart';
import '../calendario/pantalla_calendario.dart';
import '../reportes/pantalla_reportes.dart';
import '../configuracion/pantalla_configuracion.dart';
import '../formularios/pantalla_formularios.dart';
import '../horario/horario_admin_screen.dart';
import 'contenido_inicio_admin.dart';
import 'pantalla_gestion_docentes.dart';
import 'pantalla_gestion_acudientes.dart';
import 'pantalla_alertas_alumnos.dart';
import 'pantalla_clases_finalizadas.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appTitle: 'EduCampus',
      roleLabel: 'Administrador',
      userName: 'Admin',
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
            NavItem(label: 'Inicio', icon: Icons.home_rounded, screenBuilder: (_) => const AdminHomeContent()),
            NavItem(label: 'Estudiantes', icon: Icons.groups_2_rounded, screenBuilder: (_) => const EstudiantesListScreen()),
            NavItem(label: 'Docentes', icon: Icons.badge_rounded, screenBuilder: (_) => const GestionDocentesScreen()),
            NavItem(label: 'Acudientes', icon: Icons.family_restroom_rounded, screenBuilder: (_) => const GestionAcudientesScreen()),
            NavItem(label: 'Grados', icon: Icons.class_rounded, screenBuilder: (_) => const GradosScreen()),
          ],
        ),
        NavSection(
          title: 'Académico',
          items: [
            NavItem(label: 'Evaluación y logros', icon: Icons.grade_rounded, screenBuilder: (_) => const EvaluacionDocenteScreen()),
            NavItem(label: 'Asistencia', icon: Icons.event_available_rounded, screenBuilder: (_) => const AsistenciaScreen()),
            NavItem(label: 'Convivencia', icon: Icons.visibility_rounded, screenBuilder: (_) => const ConvivenciaDocenteScreen()),
            NavItem(label: 'Alertas alumnos', icon: Icons.warning_amber_rounded, screenBuilder: (_) => const AlertasAlumnosScreen()),
            NavItem(label: 'Clases finalizadas', icon: Icons.check_circle_outline_rounded, screenBuilder: (_) => const ClasesFinalizadasScreen()),
            NavItem(label: 'Calendario', icon: Icons.calendar_month_rounded, screenBuilder: (_) => const CalendarioScreen()),
            NavItem(label: 'Horario', icon: Icons.schedule_rounded, screenBuilder: (_) => const HorarioAdminScreen()),
          ],
        ),
        NavSection(
          title: 'Herramientas',
          items: [
            NavItem(label: 'Comunicación', icon: Icons.campaign_rounded, screenBuilder: (_) => const NotificacionesScreen(rol: RolNotificacion.admin)),
            NavItem(label: 'Formularios', icon: Icons.dynamic_form_rounded, screenBuilder: (_) => const FormulariosScreen()),
            NavItem(label: 'Reportes', icon: Icons.summarize_rounded, screenBuilder: (_) => const ReportesScreen()),
            NavItem(label: 'Configuración', icon: Icons.settings_rounded, screenBuilder: (_) => const ConfiguracionScreen()),
          ],
        ),
      ],
    );
  }
}