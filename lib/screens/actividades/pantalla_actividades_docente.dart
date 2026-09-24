import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colores_app.dart';
import '../../models/actividad.dart';
import '../../services/api_config.dart';
import '../../services/servicio_actividades.dart';
import '../../services/servicio_auth.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class _Curso {
  final int id;
  final String title;
  const _Curso({required this.id, required this.title});
}

class _EstudianteCurso {
  final int id;
  final String nombre;
  const _EstudianteCurso({required this.id, required this.nombre});
}

String _fmt(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

class ActividadesDocenteScreen extends StatefulWidget {
  const ActividadesDocenteScreen({super.key});

  @override
  State<ActividadesDocenteScreen> createState() => _ActividadesDocenteScreenState();
}

class _ActividadesDocenteScreenState extends State<ActividadesDocenteScreen> {
  bool _cargando = true;
  List<_Curso> _cursos = [];
  int? _cursoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    final sesion = AuthService().sesionActual;
    if (sesion == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/').replace(
        queryParameters: {'instructor_id': sesion.usuarioId.toString()},
      );
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        _cursos = datos.map((c) => _Curso(id: c['id'] as int, title: c['title'] as String)).toList();
        _cursoSeleccionado = _cursos.isNotEmpty ? _cursos.first.id : null;
      }

      if (_cursoSeleccionado != null) {
        await ActividadesService().cargarPorCursos([_cursoSeleccionado!]);
      }
    } catch (_) {}

    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    if (_cursoSeleccionado == null) return;

    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime fecha = DateTime.now().add(const Duration(days: 7));
    bool permiteVideo = false;
    bool guardando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                  const Text('Nueva actividad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    controller: tituloCtrl,
                    label: 'Título',
                    hint: 'Ej: Taller de fracciones',
                    icon: Icons.assignment_rounded,
                  ),
                  const SizedBox(height: 12),
                  LabeledTextField(
                    controller: descCtrl,
                    label: 'Descripción',
                    hint: 'Instrucciones de la actividad',
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final elegida = await showDatePicker(
                        context: context,
                        initialDate: fecha,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (elegida != null) setSheetState(() => fecha = elegida);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text('Entrega: ${_fmt(fecha)}'),
                        ],
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permitir video', style: TextStyle(fontSize: 13.5)),
                    value: permiteVideo,
                    onChanged: (v) => setSheetState(() => permiteVideo = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: guardando
                          ? null
                          : () async {
                              if (tituloCtrl.text.trim().isEmpty) return;
                              setSheetState(() => guardando = true);

                              final error = await ActividadesService().agregarActividad(
                                cursoId: _cursoSeleccionado!,
                                titulo: tituloCtrl.text.trim(),
                                descripcion: descCtrl.text.trim(),
                                fechaEntrega: fecha,
                                permiteVideo: permiteVideo,
                              );

                              if (!context.mounted) return;

                              if (error != null) {
                                setSheetState(() => guardando = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                                return;
                              }

                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Publicar actividad'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cursos.isEmpty) {
      return const Center(
        child: Text('No tienes cursos asignados todavía.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Stack(
      children: [
        ListenableBuilder(
          listenable: ActividadesService(),
          builder: (context, _) {
            final actividades = ActividadesService().actividades;

            return Column(
              children: [
                if (_cursos.length > 1)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _cursoSeleccionado,
                          isExpanded: true,
                          items: _cursos.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
                          onChanged: (v) async {
                            setState(() {
                              _cursoSeleccionado = v;
                              _cargando = true;
                            });
                            await ActividadesService().cargarPorCursos([v!]);
                            if (mounted) setState(() => _cargando = false);
                          },
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: actividades.isEmpty
                      ? const Center(
                          child: Text('Aún no hay actividades publicadas', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                          itemCount: actividades.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final a = actividades[index];
                            final entregas = ActividadesService().entregasPorActividad(a.id);
                            final calificadas = entregas.where((e) => e.calificada).length;

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
                                  child: const Icon(Icons.assignment_rounded, color: AppColors.primary),
                                ),
                                title: Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  'Entrega: ${_fmt(a.fechaEntrega)} · ${entregas.length} entregada(s), $calificadas calificada(s)',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _DetalleActividadDocenteScreen(actividad: a, cursoId: _cursoSeleccionado!),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
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

class _DetalleActividadDocenteScreen extends StatefulWidget {
  final Actividad actividad;
  final int cursoId;
  const _DetalleActividadDocenteScreen({required this.actividad, required this.cursoId});

  @override
  State<_DetalleActividadDocenteScreen> createState() => _DetalleActividadDocenteScreenState();
}

class _DetalleActividadDocenteScreenState extends State<_DetalleActividadDocenteScreen> {
  bool _cargando = true;
  List<_EstudianteCurso> _estudiantes = [];

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  Future<void> _cargarEstudiantes() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/${widget.cursoId}/estudiantes/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));
      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        _estudiantes = datos.map((e) => _EstudianteCurso(id: e['id'] as int, nombre: e['nombre'] as String)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _abrirCalificar(Entrega entrega) async {
    final notaCtrl = TextEditingController(text: entrega.nota?.toString() ?? '');
    final retroCtrl = TextEditingController(text: entrega.retroalimentacion ?? '');
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Calificar entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Nota (0.0 a 5.0)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: retroCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Retroalimentación (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      final nota = double.tryParse(notaCtrl.text.trim().replaceAll(',', '.'));
                      if (nota == null || nota < 0 || nota > 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa una nota válida entre 0.0 y 5.0')),
                        );
                        return;
                      }

                      setDialogState(() => guardando = true);

                      final error = await ActividadesService().calificarEntrega(
                        entregaId: entrega.id,
                        actividadId: widget.actividad.id,
                        nota: nota,
                        retroalimentacion: retroCtrl.text.trim(),
                      );

                      if (!context.mounted) return;

                      if (error != null) {
                        setDialogState(() => guardando = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }

                      Navigator.pop(context);
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
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
        title: Text(widget.actividad.titulo),
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
                Text(widget.actividad.descripcion),
                const SizedBox(height: 8),
                Text('Entrega: ${_fmt(widget.actividad.fechaEntrega)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (widget.actividad.permiteVideo) ...[
                  const SizedBox(height: 6),
                  const Text('Admite video', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : ListenableBuilder(
                    listenable: ActividadesService(),
                    builder: (context, _) {
                      if (_estudiantes.isEmpty) {
                        return const Center(
                          child: Text('No hay estudiantes matriculados en este curso.', style: TextStyle(color: AppColors.textSecondary)),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        itemCount: _estudiantes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final estudiante = _estudiantes[index];
                          final entrega = ActividadesService().entregaDe(widget.actividad.id, estudiante.id.toString());

                          Color chipColor;
                          String etiqueta;
                          if (entrega == null) {
                            chipColor = AppColors.danger;
                            etiqueta = 'Pendiente';
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
                                      child: Text(estudiante.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: chipColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Text(etiqueta, style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.w600)),
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
                                    child: Row(
                                      children: [
                                        const Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(entrega.nombreOriginal,
                                              style: const TextStyle(color: AppColors.primary, fontSize: 12.5),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (entrega.comentario.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(entrega.comentario, style: const TextStyle(fontSize: 12.5)),
                                  ],
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _abrirCalificar(entrega),
                                      icon: const Icon(Icons.grade_rounded, size: 16),
                                      label: Text(entrega.calificada ? 'Editar calificación' : 'Calificar'),
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
