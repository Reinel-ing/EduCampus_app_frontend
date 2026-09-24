// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colores_app.dart';
import '../../models/actividad.dart';
import '../../models/estudiante.dart';
import '../../services/api_config.dart';
import '../../services/servicio_actividades.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/campo_texto_etiquetado.dart';

String _fmt(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

class ActividadesAcudienteScreen extends StatefulWidget {
  const ActividadesAcudienteScreen({super.key});

  @override
  State<ActividadesAcudienteScreen> createState() => _ActividadesAcudienteScreenState();
}

class _ActividadesAcudienteScreenState extends State<ActividadesAcudienteScreen> {
  bool _cargando = true;
  List<Student> _misEstudiantes = [];
  final Map<String, int> _cursoDeEstudiante = {};

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);

    final correo = AuthService().sesionActual?.correo;

    if (StudentService().students.isEmpty) {
      await StudentService().cargarDesdeBackend();
    }

    _misEstudiantes = StudentService()
        .students
        .where((s) => s.acudienteCorreo.trim().toLowerCase() == correo)
        .toList();

    final cursoIds = <int>{};
    for (final estudiante in _misEstudiantes) {
      final id = int.tryParse(estudiante.id);
      if (id == null) continue;
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/').replace(
          queryParameters: {'student_id': id.toString()},
        );
        final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
        if (respuesta.statusCode == 200) {
          final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
          for (final c in datos) {
            final cursoId = c['id'] as int;
            cursoIds.add(cursoId);
            _cursoDeEstudiante['${estudiante.id}_$cursoId'] = cursoId;
          }
        }
      } catch (_) {}
    }

    await ActividadesService().cargarPorCursos(cursoIds.toList());

    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_misEstudiantes.isEmpty) {
      return const Center(
        child: Text('No se encontró un estudiante vinculado a tu cuenta.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListenableBuilder(
      listenable: ActividadesService(),
      builder: (context, _) {
        final actividades = ActividadesService().actividades;

        if (actividades.isEmpty) {
          return const Center(
            child: Text('Aún no hay actividades publicadas', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          itemCount: actividades.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final a = actividades[index];

            final estudiantesDeEstaActividad = _misEstudiantes.where((s) {
              final id = int.tryParse(s.id);
              return id != null && (_cursoDeEstudiante.containsKey('${s.id}_${a.cursoId}'));
            }).toList();

            if (estudiantesDeEstaActividad.isEmpty) return const SizedBox.shrink();

            final pendientes = estudiantesDeEstaActividad
                .where((s) => ActividadesService().entregaDe(a.id, s.id) == null)
                .length;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pendientes > 0 ? AppColors.danger.withOpacity(0.4) : const Color(0xFFE7E7EC)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (pendientes > 0 ? AppColors.danger : AppColors.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.assignment_rounded, color: pendientes > 0 ? AppColors.danger : AppColors.success),
                ),
                title: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Entrega: ${_fmt(a.fechaEntrega)}${pendientes > 0 ? ' · $pendientes pendiente(s)' : ''}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _DetalleActividadAcudienteScreen(actividad: a, estudiantes: estudiantesDeEstaActividad),
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
  final List<Student> estudiantes;
  const _DetalleActividadAcudienteScreen({required this.actividad, required this.estudiantes});

  void _abrirEntrega(BuildContext context, Student estudiante) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEntrega(actividad: actividad, estudiante: estudiante),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Text(actividad.descripcion),
                const SizedBox(height: 8),
                Text('Entrega: ${_fmt(actividad.fechaEntrega)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  actividad.permiteVideo
                      ? 'Se acepta video, PDF, Word, PowerPoint, imagen o texto.'
                      : 'Se acepta PDF, Word, PowerPoint, imagen o texto.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: ActividadesService(),
              builder: (context, _) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  itemCount: estudiantes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final estudiante = estudiantes[index];
                    final entrega = ActividadesService().entregaDe(actividad.id, estudiante.id);
                    final plazoVencido = DateTime.now().isAfter(actividad.fechaEntrega);

                    Color chipColor;
                    String etiqueta;
                    if (entrega == null) {
                      chipColor = AppColors.danger;
                      etiqueta = plazoVencido ? 'Plazo vencido' : 'Pendiente';
                    } else if (entrega.calificada) {
                      chipColor = AppColors.success;
                      etiqueta = 'Calificada (${entrega.nota!.toStringAsFixed(1)})';
                    } else {
                      chipColor = AppColors.accent;
                      etiqueta = 'Entregado';
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
                                    Text(estudiante.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: chipColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Text(etiqueta, style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                              if (entrega == null && !plazoVencido)
                                ElevatedButton.icon(
                                  onPressed: () => _abrirEntrega(context, estudiante),
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
                          if (entrega != null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => launchUrl(
                                Uri.parse(ActividadesService().urlDescargaEntrega(entrega.id)),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.download_rounded, size: 15, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(entrega.nombreOriginal,
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.primary), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (entrega.comentario.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(entrega.comentario, style: const TextStyle(fontSize: 12.5)),
                            ],
                          ],
                          if (entrega?.retroalimentacion != null && entrega!.retroalimentacion!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
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
                                  Text(entrega.retroalimentacion!, style: const TextStyle(fontSize: 12.5)),
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

const _extensionesVideo = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
const _extensionesDocumento = ['.pdf', '.doc', '.docx', '.ppt', '.pptx', '.jpg', '.jpeg', '.png', '.txt'];

class _FormularioEntrega extends StatefulWidget {
  final Actividad actividad;
  final Student estudiante;
  const _FormularioEntrega({required this.actividad, required this.estudiante});

  @override
  State<_FormularioEntrega> createState() => _FormularioEntregaState();
}

class _FormularioEntregaState extends State<_FormularioEntrega> {
  final _comentarioController = TextEditingController();
  String? _archivoNombre;
  Uint8List? _archivoBytes;
  bool _guardando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  void _pickFile() {
    final extensiones = [..._extensionesDocumento, if (widget.actividad.permiteVideo) ..._extensionesVideo];
    final input = html.FileUploadInputElement()
      ..accept = extensiones.join(',')
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

  Future<void> _guardar() async {
    if (_archivoNombre == null || _archivoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un archivo para entregar.')),
      );
      return;
    }

    final studentId = int.tryParse(widget.estudiante.id);
    if (studentId == null) return;

    setState(() => _guardando = true);

    final acudienteId = AuthService().sesionActual?.usuarioId;

    final error = await ActividadesService().subirEntrega(
      actividadId: widget.actividad.id,
      studentId: studentId,
      acudienteId: acudienteId,
      nombreArchivo: _archivoNombre!,
      archivoBytes: _archivoBytes!,
      comentario: _comentarioController.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

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
              Text('Entregar tarea · ${widget.estudiante.nombreCompleto}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              const Text('ARCHIVO',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: _archivoNombre != null ? AppColors.primary.withOpacity(0.06) : const Color(0xFFF3F4F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _archivoNombre != null ? AppColors.primary.withOpacity(0.35) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _archivoNombre != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                        color: _archivoNombre != null ? AppColors.success : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _archivoNombre ??
                              (widget.actividad.permiteVideo
                                  ? 'Video, PDF, Word, PowerPoint, imagen o texto'
                                  : 'PDF, Word, PowerPoint, imagen o texto'),
                          style: TextStyle(color: _archivoNombre != null ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _guardando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enviar entrega'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
