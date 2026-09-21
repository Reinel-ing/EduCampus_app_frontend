import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../models/situacion_convivencia.dart';
import '../../services/servicio_convivencia.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/campo_texto_etiquetado.dart';

String _formatearFecha(DateTime fecha) {
  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}

class ConvivenciaDocenteScreen extends StatelessWidget {
  const ConvivenciaDocenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estudiantesService = StudentService();
    final convivenciaService = ConvivenciaService();

    return ListenableBuilder(
      listenable: Listenable.merge([estudiantesService, convivenciaService]),
      builder: (context, _) {
        final estudiantes = estudiantesService.students;

        if (estudiantes.isEmpty) {
          return const Center(
            child: Text(
              'Aún no hay estudiantes registrados',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          itemCount: estudiantes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final s = estudiantes[index];
            final situaciones = convivenciaService.porEstudiante(s.id);
            final pendientes = situaciones.where((sit) => !sit.seguimientoRealizado).length;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E7EC)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    s.nombres.isNotEmpty ? s.nombres[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  situaciones.isEmpty
                      ? '${s.grado} · Sin situaciones registradas'
                      : '${s.grado} · ${situaciones.length} situación(es)',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pendientes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pendientes pendiente(s)',
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _ConvivenciaEstudianteScreen(estudiante: s)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ConvivenciaEstudianteScreen extends StatelessWidget {
  final Student estudiante;

  const _ConvivenciaEstudianteScreen({required this.estudiante});

  void _abrirFormulario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioSituacion(estudiante: estudiante),
    );
  }

  void _abrirSeguimiento(BuildContext context, SituacionConvivencia situacion) {
    final controller = TextEditingController(text: situacion.notaSeguimiento);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(situacion.seguimientoRealizado ? 'Actualizar seguimiento' : 'Registrar seguimiento'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe el acompañamiento realizado'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              ConvivenciaService().marcarSeguimiento(
                situacion.id,
                realizado: true,
                nota: controller.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ConvivenciaService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(estudiante.nombreCompleto),
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final situaciones = service.porEstudiante(estudiante.id);

          if (situaciones.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay situaciones registradas para este estudiante',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            itemCount: situaciones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final sit = situaciones[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7E7EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sit.tipo.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(sit.tipo.icono, color: sit.tipo.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(sit.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Text(
                                    sit.tipo.etiqueta,
                                    style: TextStyle(fontSize: 11.5, color: sit.tipo.color, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatearFecha(sit.fecha),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                              ),
                              if (sit.descripcion.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(sit.descripcion, style: const TextStyle(fontSize: 13.5)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (sit.seguimientoRealizado) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Seguimiento realizado',
                                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12.5),
                                ),
                              ],
                            ),
                            if (sit.notaSeguimiento.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(sit.notaSeguimiento, style: const TextStyle(fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _abrirSeguimiento(context, sit),
                          child: const Text('Editar seguimiento'),
                        ),
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _abrirSeguimiento(context, sit),
                          icon: const Icon(Icons.visibility_rounded, size: 16),
                          label: const Text('Registrar acompañamiento'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva situación'),
      ),
    );
  }
}

class _FormularioSituacion extends StatefulWidget {
  final Student estudiante;

  const _FormularioSituacion({required this.estudiante});

  @override
  State<_FormularioSituacion> createState() => _FormularioSituacionState();
}

class _FormularioSituacionState extends State<_FormularioSituacion> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  TipoSituacion _tipo = TipoSituacion.positiva;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    ConvivenciaService().agregar(
      estudianteId: widget.estudiante.id,
      tipo: _tipo,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Text(
                  'Nueva situación · ${widget.estudiante.nombreCompleto}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                SegmentedButton<TipoSituacion>(
                  segments: const [
                    ButtonSegment(
                      value: TipoSituacion.positiva,
                      label: Text('Positiva'),
                      icon: Icon(Icons.thumb_up_rounded),
                    ),
                    ButtonSegment(
                      value: TipoSituacion.negativa,
                      label: Text('Negativa'),
                      icon: Icon(Icons.report_problem_rounded),
                    ),
                    ButtonSegment(
                      value: TipoSituacion.neutral,
                      label: Text('Info.'),
                      icon: Icon(Icons.info_rounded),
                    ),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (nuevo) => setState(() => _tipo = nuevo.first),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  controller: _tituloController,
                  label: 'Título de la situación',
                  hint: 'Ej. Excelente trabajo en equipo',
                  icon: Icons.edit_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _descripcionController,
                  label: 'Descripción',
                  hint: 'Describe lo ocurrido con el mayor detalle posible',
                  icon: Icons.notes_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa una descripción' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Guardar situación'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}