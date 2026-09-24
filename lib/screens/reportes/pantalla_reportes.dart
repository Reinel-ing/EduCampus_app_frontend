import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_docentes.dart';
import '../../services/servicio_evaluacion.dart';
import '../../services/servicio_convivencia.dart';
import '../../services/servicio_asistencia_backend.dart';
import '../../models/situacion_convivencia.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String? _asistenciaHoy;

  @override
  void initState() {
    super.initState();
    _cargarAsistenciaHoy();

    final estudiantesService = StudentService();
    estudiantesService.cargarDesdeBackendSiHaceFalta().then((_) {
      if (estudiantesService.students.isNotEmpty) {
        EvaluacionService().cargarPorEstudiantes(estudiantesService.students.map((s) => s.id).toList());
      }
    });
    TeacherService().cargarDesdeBackend();
    ConvivenciaService().cargarDesdeBackendSiHaceFalta();
  }

  Future<void> _cargarAsistenciaHoy() async {
    final registros = await AsistenciaBackendService().listarPorFecha(DateTime.now());

    if (!mounted) return;

    if (registros.isEmpty) {
      setState(() => _asistenciaHoy = 'N/A');
      return;
    }

    final presentes = registros
        .where((r) => r.status == 'presente' || r.status == 'tarde')
        .length;

    setState(() => _asistenciaHoy = '${(presentes / registros.length * 100).toStringAsFixed(0)}%');
  }

  Widget _tarjeta({required String titulo, required String valor, required IconData icono, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(titulo,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
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

    return ListenableBuilder(
      listenable: Listenable.merge([
        estudiantesService,
        docentesService,
        evaluacionService,
        convivenciaService,
      ]),
      builder: (context, _) {
        final estudiantes = estudiantesService.students;
        final docentes = docentesService.teachers;
        final registros = evaluacionService.registros;
        final situaciones = convivenciaService.situaciones;

        final notas = registros.map((r) => r.score).toList();
        final promedioGeneral = notas.isEmpty ? null : notas.reduce((a, b) => a + b) / notas.length;

        final positivas = situaciones.where((s) => s.tipo == TipoSituacion.positiva).length;
        final negativas = situaciones.where((s) => s.tipo == TipoSituacion.negativa).length;

        final anchoPantalla = MediaQuery.of(context).size.width;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GridView.count(
              crossAxisCount: anchoPantalla >= 900 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: anchoPantalla >= 900 ? 2.4 : (anchoPantalla >= 400 ? 1.9 : 1.5),
              children: [
                _tarjeta(titulo: 'Estudiantes', valor: '${estudiantes.length}', icono: Icons.groups_2_rounded, color: AppColors.primary),
                _tarjeta(titulo: 'Docentes', valor: '${docentes.length}', icono: Icons.badge_rounded, color: AppColors.accent),
                _tarjeta(
                  titulo: 'Promedio general',
                  valor: promedioGeneral == null ? 'N/A' : promedioGeneral.toStringAsFixed(1),
                  icono: Icons.grade_rounded,
                  color: AppColors.success,
                ),
                _tarjeta(
                  titulo: 'Asistencia de hoy',
                  valor: _asistenciaHoy ?? '...',
                  icono: Icons.event_available_rounded,
                  color: AppColors.success,
                ),
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
