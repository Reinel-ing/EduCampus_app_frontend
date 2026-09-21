import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_docentes.dart';
import '../../services/servicio_evaluacion.dart';
import '../../services/servicio_convivencia.dart';
import '../../services/servicio_asistencia.dart';
import '../../models/registro_academico.dart';
import '../../models/situacion_convivencia.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  Widget _tarjeta({required String titulo, required String valor, required IconData icono, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary)),
                Text(titulo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estudiantesService = StudentService();
    final docentesService = TeacherService();
    final evaluacionService = EvaluacionService();
    final convivenciaService = ConvivenciaService();
    final asistenciaService = AsistenciaService();

    return ListenableBuilder(
      listenable: Listenable.merge([
        estudiantesService,
        docentesService,
        evaluacionService,
        convivenciaService,
        asistenciaService,
      ]),
      builder: (context, _) {
        final estudiantes = estudiantesService.students;
        final docentes = docentesService.teachers;
        final registros = evaluacionService.registros;
        final situaciones = convivenciaService.situaciones;

        final notas = registros
            .where((r) => r.tipo == TipoRegistroAcademico.nota && r.calificacion != null)
            .map((r) => r.calificacion!)
            .toList();
        final promedioGeneral = notas.isEmpty ? null : notas.reduce((a, b) => a + b) / notas.length;

        final positivas = situaciones.where((s) => s.tipo == TipoSituacion.positiva).length;
        final negativas = situaciones.where((s) => s.tipo == TipoSituacion.negativa).length;

        final asistenciaHoy = (asistenciaService.porcentajeAsistenciaHoy() * 100).toStringAsFixed(0);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: [
                _tarjeta(titulo: 'Estudiantes', valor: '${estudiantes.length}', icono: Icons.groups_2_rounded, color: AppColors.primary),
                _tarjeta(titulo: 'Docentes', valor: '${docentes.length}', icono: Icons.badge_rounded, color: AppColors.accent),
                _tarjeta(
                  titulo: 'Promedio general',
                  valor: promedioGeneral == null ? 'N/A' : promedioGeneral.toStringAsFixed(1),
                  icono: Icons.grade_rounded,
                  color: AppColors.success,
                ),
                _tarjeta(titulo: 'Asistencia de hoy', valor: '$asistenciaHoy%', icono: Icons.event_available_rounded, color: AppColors.success),
                _tarjeta(titulo: 'Situaciones positivas', valor: '$positivas', icono: Icons.thumb_up_rounded, color: AppColors.success),
                _tarjeta(titulo: 'Situaciones negativas', valor: '$negativas', icono: Icons.report_problem_rounded, color: AppColors.danger),
              ],
            ),
          ],
        );
      },
    );
  }
}