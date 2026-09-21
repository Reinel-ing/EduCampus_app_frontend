import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/actividad.dart';
import '../../models/estudiante.dart';
import '../../services/servicio_actividades.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/campo_texto_etiquetado.dart';

String _fmt(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

class ActividadesAcudienteScreen extends StatelessWidget {
  const ActividadesAcudienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actService = ActividadesService();
    final stuService = StudentService();

    return ListenableBuilder(
      listenable: Listenable.merge([actService, stuService]),
      builder: (context, _) {
        final actividades = actService.actividades;

        if (actividades.isEmpty) {
          return const Center(
            child: Text('Aún no hay actividades publicadas',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        final pendientes = actividades.where((a) {
          final entregas = actService.entregasPorActividad(a.id);
          return entregas.any((e) => e.estado == EstadoEntrega.pendiente);
        }).toList();

        final otras = actividades.where((a) => !pendientes.contains(a)).toList();
        final ordenadas = [...pendientes, ...otras];

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          itemCount: ordenadas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final a = ordenadas[index];
            final entregas = actService.entregasPorActividad(a.id);
            final pendientesCount = entregas.where((e) => e.estado == EstadoEntrega.pendiente).length;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pendientesCount > 0 ? AppColors.danger.withOpacity(0.4) : const Color(0xFFE7E7EC),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (pendientesCount > 0 ? AppColors.danger : AppColors.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: pendientesCount > 0 ? AppColors.danger : AppColors.success,
                  ),
                ),
                title: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${a.materia} · ${a.grado}'),
                      const SizedBox(height: 4),
                      Text('Entrega: ${_fmt(a.fechaEntrega)}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      if (pendientesCount > 0)
                        Text('$pendientesCount pendiente(s)',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.danger, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _DetalleActividadAcudienteScreen(actividad: a),
                    ),
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

class _DetalleActividadAcudienteScreen extends StatelessWidget {
  final Actividad actividad;
  const _DetalleActividadAcudienteScreen({required this.actividad});

  void _abrirEntrega(BuildContext context, Entrega entrega, String nombreEstudiante) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEntrega(entrega: entrega, nombreEstudiante: nombreEstudiante),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actService = ActividadesService();
    final stuService = StudentService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(actividad.titulo),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E7EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${actividad.materia} · ${actividad.grado}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(actividad.descripcion),
                const SizedBox(height: 8),
                Text('Entrega: ${_fmt(actividad.fechaEntrega)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (actividad.guiaUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            actividad.guiaUrl,
                            style: const TextStyle(color: AppColors.primary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: actService,
              builder: (context, _) {
                final entregas = actService.entregasPorActividad(actividad.id);

                if (entregas.isEmpty) {
                  return const Center(
                    child: Text('No hay estudiantes registrados en este grado',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  itemCount: entregas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entrega = entregas[index];
                    final estudiante = stuService.students.firstWhere(
                      (Student s) => s.id == entrega.estudianteId,
                      orElse: () => Student(
                        id: entrega.estudianteId,
                        nombres: 'Estudiante',
                        apellidos: 'eliminado',
                        fechaNacimiento: '',
                        grado: '',
                        acudienteNombre: '',
                        acudienteTelefono: '',
                        acudienteParentesco: '',
                      ),
                    );

                    Color chipColor;
                    switch (entrega.estado) {
                      case EstadoEntrega.pendiente:
                        chipColor = AppColors.danger;
                        break;
                      case EstadoEntrega.entregado:
                        chipColor = AppColors.accent;
                        break;
                      case EstadoEntrega.revisado:
                        chipColor = AppColors.success;
                        break;
                    }

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
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(estudiante.nombreCompleto,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: chipColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        entrega.estado.etiqueta,
                                        style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (entrega.estado == EstadoEntrega.pendiente)
                                ElevatedButton.icon(
                                  onPressed: () => _abrirEntrega(context, entrega, estudiante.nombreCompleto),
                                  icon: const Icon(Icons.upload_rounded, size: 16),
                                  label: const Text('Entregar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                            ],
                          ),
                          if (entrega.archivoUrl.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tu entrega:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(entrega.archivoUrl,
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
                                  if (entrega.comentarioAcudiente.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(entrega.comentarioAcudiente, style: const TextStyle(fontSize: 12.5)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          if (entrega.retroalimentacion.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                                      SizedBox(width: 6),
                                      Text('Retroalimentación del docente:',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(entrega.retroalimentacion, style: const TextStyle(fontSize: 12.5)),
                                ],
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
          ),
        ],
      ),
    );
  }
}

class _FormularioEntrega extends StatefulWidget {
  final Entrega entrega;
  final String nombreEstudiante;
  const _FormularioEntrega({required this.entrega, required this.nombreEstudiante});

  @override
  State<_FormularioEntrega> createState() => _FormularioEntregaState();
}

class _FormularioEntregaState extends State<_FormularioEntrega> {
  final _urlController = TextEditingController();
  final _comentarioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    ActividadesService().subirEntregaAcudiente(
      entregaId: widget.entrega.id,
      archivoUrl: _urlController.text.trim(),
      comentario: _comentarioController.text.trim(),
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
                'Entregar tarea · ${widget.nombreEstudiante}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                controller: _urlController,
                label: 'Enlace del trabajo',
                hint: 'https://drive.google.com/...',
                icon: Icons.link_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el enlace del trabajo' : null,
              ),
              const SizedBox(height: 12),
              LabeledTextField(
                controller: _comentarioController,
                label: 'Comentario (opcional)',
                hint: 'Alguna nota para el docente',
                icon: Icons.comment_rounded,
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
                  child: const Text('Enviar entrega'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}