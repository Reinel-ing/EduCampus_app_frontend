// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/colores_app.dart';
import '../../models/material_didactico.dart';
import '../../services/api_config.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_materiales.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class _Curso {
  final int id;
  final String title;
  const _Curso({required this.id, required this.title});
}

String _fmt(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

void _descargarArchivo(String nombre, Uint8List bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
}

class MaterialesScreen extends StatefulWidget {
  const MaterialesScreen({super.key});

  @override
  State<MaterialesScreen> createState() => _MaterialesScreenState();
}

class _MaterialesScreenState extends State<MaterialesScreen> {
  bool get _esDocente => AuthService().sesionActual?.rol == 'profesor';

  bool _cargando = true;
  List<_Curso> _cursos = [];
  final Map<int, String> _tituloCurso = {};

  @override
  void initState() {
    super.initState();
    _cargarCursosYMateriales();
  }

  Future<void> _cargarCursosYMateriales() async {
    setState(() => _cargando = true);

    final sesion = AuthService().sesionActual;

    try {
      if (_esDocente) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/').replace(
          queryParameters: {'instructor_id': sesion!.usuarioId.toString()},
        );
        final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
        if (respuesta.statusCode == 200) {
          final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
          _cursos = datos.map((c) => _Curso(id: c['id'] as int, title: c['title'] as String)).toList();
        }
      } else {
        if (StudentService().students.isEmpty) {
          await StudentService().cargarDesdeBackend();
        }
        final misHijos = StudentService()
            .students
            .where((s) => s.acudienteCorreo.trim().toLowerCase() == sesion?.correo)
            .toList();

        final cursosDeHijos = <int, _Curso>{};
        for (final hijo in misHijos) {
          final id = int.tryParse(hijo.id);
          if (id == null) continue;
          final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/').replace(
            queryParameters: {'student_id': id.toString()},
          );
          final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
          if (respuesta.statusCode == 200) {
            final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
            for (final c in datos) {
              final curso = _Curso(id: c['id'] as int, title: c['title'] as String);
              cursosDeHijos[curso.id] = curso;
            }
          }
        }
        _cursos = cursosDeHijos.values.toList();
      }

      for (final c in _cursos) {
        _tituloCurso[c.id] = c.title;
      }

      await MaterialService().cargarPorCursos(_cursos.map((c) => c.id).toList());
    } catch (_) {}

    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    if (_cursos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes cursos asignados todavía.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioMaterial(cursos: _cursos),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, MaterialDidactico m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar material'),
        content: Text('¿Eliminar "${m.titulo}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final error = await MaterialService().eliminar(m.id);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = MaterialService();

    return Stack(
      children: [
        ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            if (_cargando) {
              return const Center(child: CircularProgressIndicator());
            }

            final materiales = service.materiales;
            if (materiales.isEmpty) {
              return const Center(
                child: Text('Aún no hay materiales publicados',
                    style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: materiales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = materiales[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7EC)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          m.tieneArchivo
                              ? Icons.attach_file_rounded
                              : Icons.folder_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.titulo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '${_tituloCurso[m.cursoId] ?? 'Curso'}${m.materia.isNotEmpty ? ' · ${m.materia}' : ''} · ${_fmt(m.fecha)}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5),
                            ),
                            if (m.descripcion.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(m.descripcion,
                                  style: const TextStyle(fontSize: 13.5)),
                            ],
                            if (m.tieneArchivo) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _descargarArchivo(
                                    m.archivoNombre, m.archivoBytes!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons.download_rounded,
                                          size: 15,
                                          color: AppColors.primary),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          m.archivoNombre,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (m.enlace.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                m.enlace,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_esDocente)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger),
                          onPressed: () => _confirmarEliminar(context, m),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        if (_esDocente)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo material'),
            ),
          ),
      ],
    );
  }
}

class _FormularioMaterial extends StatefulWidget {
  final List<_Curso> cursos;
  const _FormularioMaterial({required this.cursos});

  @override
  State<_FormularioMaterial> createState() => _FormularioMaterialState();
}

class _FormularioMaterialState extends State<_FormularioMaterial> {
  final _formKey = GlobalKey<FormState>();
  final _tituloC = TextEditingController();
  final _descC = TextEditingController();
  final _materiaC = TextEditingController();
  final _enlaceC = TextEditingController();
  late int _cursoId = widget.cursos.first.id;
  String? _archivoNombre;
  Uint8List? _archivoBytes;
  bool _guardando = false;

  @override
  void dispose() {
    _tituloC.dispose();
    _descC.dispose();
    _materiaC.dispose();
    _enlaceC.dispose();
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final error = await MaterialService().agregar(
      cursoId: _cursoId,
      titulo: _tituloC.text.trim(),
      descripcion: _descC.text.trim(),
      materia: _materiaC.text.trim(),
      enlace: _enlaceC.text.trim(),
      archivoNombre: _archivoNombre,
      archivoBytes: _archivoBytes,
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
                const Text('Nuevo material',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                LabeledTextField(
                  controller: _tituloC,
                  label: 'Título',
                  hint: 'Ej: Guía de fracciones',
                  icon: Icons.title_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _materiaC,
                  label: 'Materia',
                  hint: 'Ej: Matemáticas',
                  icon: Icons.menu_book_rounded,
                ),
                const SizedBox(height: 12),
                const Text('CURSO',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _cursoId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF3F4F7),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                  items: widget.cursos
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
                      .toList(),
                  onChanged: (v) => setState(() => _cursoId = v ?? _cursoId),
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _descC,
                  label: 'Descripción',
                  hint: 'Detalles del material (opcional)',
                  icon: Icons.notes_rounded,
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _enlaceC,
                  label: 'Enlace (opcional)',
                  hint: 'https://...',
                  icon: Icons.link_rounded,
                ),
                const SizedBox(height: 12),
                // ── ADJUNTO ──
                const Text('ARCHIVO ADJUNTO',
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
                            _archivoNombre ?? 'Seleccionar archivo (PDF, Word, etc.)',
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
                                size: 18, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Publicar material'),
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
