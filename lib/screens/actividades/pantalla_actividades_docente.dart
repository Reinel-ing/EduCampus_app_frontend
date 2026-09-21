// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/actividad.dart';
import '../../models/estudiante.dart';
import '../../services/servicio_actividades.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/campo_texto_etiquetado.dart';

const List<String> _gradosDisponibles = [
  'Prejardín', 'Jardín', 'Transición',
  'Primero', 'Segundo', 'Tercero', 'Cuarto', 'Quinto',
];

String formatearFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

void _descargar(String nombre, Uint8List bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
}

class ActividadesDocenteScreen extends StatelessWidget {
  const ActividadesDocenteScreen({super.key});

  void _abrirFormulario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormularioActividad(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ActividadesService();
    return Stack(
      children: [
        ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final actividades = service.actividades;
            if (actividades.isEmpty) {
              return const Center(
                child: Text('Aún no has publicado actividades',
                    style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: actividades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final a = actividades[index];
                final entregas = service.entregasPorActividad(a.id);
                final entregadas = service.entregadasPorActividad(a.id);
                final vencida = a.fechaEntrega.isBefore(DateTime.now());
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7EC)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_rounded,
                          color: AppColors.primary),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(a.titulo,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if (a.tieneArchivo)
                          const Icon(Icons.attach_file_rounded,
                              size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${a.materia} · ${a.grado}'),
                          const SizedBox(height: 4),
                          Text(
                            'Entrega: ${formatearFecha(a.fechaEntrega)}${vencida ? ' (vencida)' : ''}',
                            style: TextStyle(
                              color: vencida
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$entregadas de ${entregas.length} entregaron',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              _DetalleActividadScreen(actividad: a)),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _abrirFormulario(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva actividad'),
          ),
        ),
      ],
    );
  }
}

// ─── Detalle ────────────────────────────────────────────────────────────────

class _DetalleActividadScreen extends StatelessWidget {
  final Actividad actividad;
  const _DetalleActividadScreen({required this.actividad});

  void _abrirRetro(BuildContext context, String entregaId, String actual) {
    final c = TextEditingController(text: actual);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retroalimentación'),
        content: TextField(
          controller: c,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Escribe retroalimentación para el estudiante'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              ActividadesService().actualizarEstadoEntrega(
                entregaId,
                EstadoEntrega.revisado,
                retroalimentacion: c.text.trim(),
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
    final actSvc = ActividadesService();
    final estSvc = StudentService();
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
          // Info card
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
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(actividad.descripcion),
                const SizedBox(height: 8),
                Text(
                  'Entrega: ${formatearFecha(actividad.fechaEntrega)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (actividad.tieneArchivo) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _descargar(
                        actividad.archivoNombre, actividad.archivoBytes!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            actividad.archivoNombre,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: actSvc,
              builder: (context, _) {
                final entregas = actSvc.entregasPorActividad(actividad.id);
                if (entregas.isEmpty) {
                  return const Center(
                    child: Text(
                        'No hay estudiantes registrados en este grado',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  itemCount: entregas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final entrega = entregas[i];
                    final estudiante = estSvc.students.firstWhere(
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
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE7E7EC)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(estudiante.nombreCompleto,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                _EstadoChip(estado: entrega.estado),
                                if (entrega.tieneArchivo) ...[
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _descargar(
                                        entrega.archivoNombre,
                                        entrega.archivoBytes!),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.file_download_outlined,
                                            size: 14,
                                            color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          entrega.archivoNombre,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<EstadoEntrega>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (estado) {
                              if (estado == EstadoEntrega.revisado) {
                                _abrirRetro(context, entrega.id,
                                    entrega.retroalimentacion);
                              } else {
                                actSvc.actualizarEstadoEntrega(
                                    entrega.id, estado);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: EstadoEntrega.pendiente,
                                  child: Text('Marcar pendiente')),
                              PopupMenuItem(
                                  value: EstadoEntrega.entregado,
                                  child: Text('Marcar entregado')),
                              PopupMenuItem(
                                  value: EstadoEntrega.revisado,
                                  child: Text(
                                      'Revisar y retroalimentar')),
                            ],
                          ),
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

// ─── Estado chip ────────────────────────────────────────────────────────────

class _EstadoChip extends StatelessWidget {
  final EstadoEntrega estado;
  const _EstadoChip({required this.estado});

  Color get _color {
    switch (estado) {
      case EstadoEntrega.pendiente:
        return AppColors.danger;
      case EstadoEntrega.entregado:
        return AppColors.accent;
      case EstadoEntrega.revisado:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: _color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(estado.etiqueta,
          style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Formulario nueva actividad ──────────────────────────────────────────────

class _FormularioActividad extends StatefulWidget {
  const _FormularioActividad();

  @override
  State<_FormularioActividad> createState() => _FormularioActividadState();
}

class _FormularioActividadState extends State<_FormularioActividad> {
  final _formKey = GlobalKey<FormState>();
  final _materiaC = TextEditingController();
  final _tituloC = TextEditingController();
  final _descC = TextEditingController();
  String _grado = _gradosDisponibles.first;
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 7));
  String? _archivoNombre;
  Uint8List? _archivoBytes;

  @override
  void dispose() {
    _materiaC.dispose();
    _tituloC.dispose();
    _descC.dispose();
    super.dispose();
  }

  void _pickFile() {
    final input = html.FileUploadInputElement()
      ..accept =
          '.pdf,.doc,.docx,.ppt,.pptx,.xls,.xlsx,.txt,.jpg,.jpeg,.png,.zip'
      ..click();
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is List<int>) {
          setState(() {
            _archivoNombre = file.name;
            _archivoBytes = Uint8List.fromList(result);
          });
        }
      });
    });
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fechaEntrega = fecha);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    ActividadesService().agregarActividad(
      materia: _materiaC.text.trim(),
      grado: _grado,
      titulo: _tituloC.text.trim(),
      descripcion: _descC.text.trim(),
      fechaEntrega: _fechaEntrega,
      archivoNombre: _archivoNombre ?? '',
      archivoBytes: _archivoBytes,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const Text('Nueva actividad',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                LabeledTextField(
                  controller: _materiaC,
                  label: 'Materia',
                  hint: 'Ej. Ciencias Naturales',
                  icon: Icons.menu_book_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa la materia'
                      : null,
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _tituloC,
                  label: 'Título de la actividad',
                  hint: 'Ej. Guía sobre el ciclo del agua',
                  icon: Icons.edit_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa un título'
                      : null,
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _descC,
                  label: 'Instrucciones',
                  hint: 'Describe la actividad',
                  icon: Icons.notes_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 12),
                const Text('GRADO',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _grado,
                      isExpanded: true,
                      items: _gradosDisponibles
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _grado = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('FECHA DE ENTREGA',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _elegirFecha,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F7),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(formatearFecha(_fechaEntrega)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── ADJUNTO ──
                const Text('ARCHIVO ADJUNTO (OPCIONAL)',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: _archivoNombre != null
                          ? AppColors.primary.withOpacity(0.06)
                          : const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _archivoNombre != null
                            ? AppColors.primary.withOpacity(0.35)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _archivoNombre != null
                              ? Icons.check_circle_rounded
                              : Icons.upload_file_rounded,
                          color: _archivoNombre != null
                              ? AppColors.success
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _archivoNombre ??
                                'Seleccionar archivo (PDF, Word, etc.)',
                            style: TextStyle(
                              color: _archivoNombre != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_archivoNombre != null)
                          GestureDetector(
                            onTap: () => setState(() {
                              _archivoNombre = null;
                              _archivoBytes = null;
                            }),
                            child: const Icon(Icons.close_rounded,
                                size: 18,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Publicar actividad'),
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