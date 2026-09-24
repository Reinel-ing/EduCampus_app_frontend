// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../models/registro_academico.dart';
import '../../services/api_config.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_evaluacion.dart';
import '../../widgets/campo_texto_etiquetado.dart';

const _preescolar = ['Prejardín', 'Jardín', 'Transición'];

bool _esPreescolar(String grado) => _preescolar.contains(grado);

Color _colorPromedio(double p) {
  if (p >= 4.0) return AppColors.success;
  if (p >= 3.0) return AppColors.accent;
  return AppColors.danger;
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class EvaluacionDocenteScreen extends StatefulWidget {
  const EvaluacionDocenteScreen({super.key});

  @override
  State<EvaluacionDocenteScreen> createState() => _EvaluacionDocenteScreenState();
}

class _EvaluacionDocenteScreenState extends State<EvaluacionDocenteScreen> {
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (StudentService().students.isEmpty) {
      await StudentService().cargarDesdeBackend();
    }
    if (!mounted) return;

    final sesion = AuthService().sesionActual;
    final esAcudiente = sesion?.rol == 'acudiente';

    final estudiantes = esAcudiente
        ? StudentService().students.where((s) => s.acudienteCorreo.trim().toLowerCase() == sesion?.correo)
        : StudentService().students;

    await EvaluacionService().cargarPorEstudiantes(estudiantes.map((s) => s.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final estSvc = StudentService();
    final evalSvc = EvaluacionService();

    return ListenableBuilder(
      listenable: Listenable.merge([estSvc, evalSvc]),
      builder: (context, _) {
        final sesion = AuthService().sesionActual;
        final esAcudiente = sesion?.rol == 'acudiente';

        final estudiantes = esAcudiente
            ? estSvc.students
                .where((s) => s.acudienteCorreo.trim().toLowerCase() == sesion?.correo)
                .toList()
            : estSvc.students;

        if (estudiantes.isEmpty) {
          if (estSvc.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Text(
              esAcudiente
                  ? 'No se encontró un estudiante vinculado a tu cuenta.'
                  : 'Aún no hay estudiantes registrados',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        // Separar preescolar y primaria
        final preescolarList =
            estudiantes.where((s) => _esPreescolar(s.grado)).toList();
        final primariaList =
            estudiantes.where((s) => !_esPreescolar(s.grado)).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            if (preescolarList.isNotEmpty) ...[
              _seccionHeader('🌱 Preescolar',
                  'Evaluación por logros y observaciones',
                  color: Colors.teal),
              const SizedBox(height: 10),
              ...preescolarList.map(
                  (s) => _tarjetaEstudiante(context, s, evalSvc, esPreescolar: true)),
              const SizedBox(height: 20),
            ],
            if (primariaList.isNotEmpty) ...[
              _seccionHeader('📚 Primaria', 'Evaluación con notas numéricas (1.0 – 5.0)',
                  color: AppColors.primary),
              const SizedBox(height: 10),
              ...primariaList.map(
                  (s) => _tarjetaEstudiante(context, s, evalSvc, esPreescolar: false)),
            ],
          ],
        );
      },
    );
  }

  Widget _seccionHeader(String titulo, String subtitulo,
      {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
              Text(subtitulo,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaEstudiante(
      BuildContext context, Student s, EvaluacionService evalSvc,
      {required bool esPreescolar}) {
    final registros = evalSvc.porEstudiante(s.id);
    final promedio = esPreescolar ? null : evalSvc.promedioPorEstudiante(s.id);
    final cantLogros = registros.where((r) => r.logro.trim().isNotEmpty).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
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
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title:
              Text(s.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            esPreescolar
                ? '${s.grado} · $cantLogros logro(s) registrado(s)'
                : '${s.grado} · ${registros.length} registro(s)',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!esPreescolar && promedio != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _colorPromedio(promedio).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promedio.toStringAsFixed(1),
                    style: TextStyle(
                        color: _colorPromedio(promedio),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              if (esPreescolar && cantLogros > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$cantLogros ✓',
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _EvaluacionEstudianteScreen(estudiante: s),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Detalle por estudiante ───────────────────────────────────────────────────

class _EvaluacionEstudianteScreen extends StatelessWidget {
  final Student estudiante;
  const _EvaluacionEstudianteScreen({required this.estudiante});

  bool get _esDocente => AuthService().sesionActual?.rol == 'profesor';

  void _abrirFormulario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioRegistro(estudiante: estudiante),
    );
  }

  Future<void> _descargarBoletin(BuildContext context) async {
    final periodo = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Descargar boletín'),
        children: periodosValidos
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, p),
                  child: Text('Periodo $p'),
                ))
            .toList(),
      ),
    );

    if (periodo == null) return;

    final id = int.tryParse(estudiante.id);
    if (id == null) return;

    final uri = Uri.parse('${ApiConfig.baseUrl}/estudiantes/$id/boletin/').replace(
      queryParameters: {'periodo': periodo},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando boletín...'), duration: Duration(seconds: 2)),
    );

    String? error;

    try {
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final blob = html.Blob([respuesta.bodyBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'boletin_${estudiante.nombreCompleto.replaceAll(' ', '_')}_$periodo.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        return;
      }

      error = 'No se puede generar el boletín de este periodo.';
      try {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
        if (datos['detail'] is String) error = datos['detail'];
      } catch (_) {}
    } catch (_) {
      error = 'No fue posible conectar con el servidor.';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error!)));
    }
  }

  Future<void> _editarObservacion(BuildContext context, String periodo) async {
    final actual = EvaluacionService().observacion(estudiante.id, periodo)?.texto ?? '';
    final ctrl = TextEditingController(text: actual);
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Observación general · Periodo $periodo'),
          content: TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Comentario general del boletín para este periodo'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      setDialogState(() => guardando = true);

                      final error = await EvaluacionService().guardarObservacion(
                        estudianteId: estudiante.id,
                        periodo: periodo,
                        texto: ctrl.text.trim(),
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
    final service = EvaluacionService();
    final preescolar = _esPreescolar(estudiante.grado);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(estudiante.nombreCompleto),
        actions: [
          if (!_esDocente)
            IconButton(
              tooltip: 'Descargar boletín',
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger),
              onPressed: () => _descargarBoletin(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Badge de nivel
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: preescolar
                  ? Colors.teal.withOpacity(0.08)
                  : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  preescolar
                      ? Icons.emoji_events_rounded
                      : Icons.grade_rounded,
                  color: preescolar ? Colors.teal : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  preescolar
                      ? 'Preescolar — evaluación por logros y observaciones'
                      : 'Primaria — calificación numérica (1.0 a 5.0)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: preescolar ? Colors.teal : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_esDocente)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Wrap(
                spacing: 8,
                children: periodosValidos
                    .map((p) => OutlinedButton(
                          onPressed: () => _editarObservacion(context, p),
                          child: Text('Observación $p'),
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: service,
              builder: (context, _) {
                final registros = service.porEstudiante(estudiante.id);
                if (registros.isEmpty) {
                  return const Center(
                    child: Text(
                        'Aún no hay registros para este estudiante',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  itemCount: registros.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final r = registros[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFE7E7EC)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _colorPromedio(r.score).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              r.score.toStringAsFixed(1),
                              style: TextStyle(
                                  color: _colorPromedio(r.score),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(r.cursoTitulo,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Text('Periodo ${r.periodo}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                                if (r.logro.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r.logro,
                                      style: const TextStyle(fontSize: 13.5)),
                                ],
                              ],
                            ),
                          ),
                          if (_esDocente)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 20, color: AppColors.danger),
                              onPressed: () =>
                                  EvaluacionService().eliminar(r.id),
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
      floatingActionButton: _esDocente
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar registro'),
            )
          : null,
    );
  }
}

// ─── Formulario ──────────────────────────────────────────────────────────────

class _Curso {
  final int id;
  final String title;
  const _Curso({required this.id, required this.title});
}

class _FormularioRegistro extends StatefulWidget {
  final Student estudiante;
  const _FormularioRegistro({required this.estudiante});

  @override
  State<_FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<_FormularioRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _logroC = TextEditingController();
  final _notaC = TextEditingController();

  late bool _soloLogros;
  String _periodo = periodosValidos.first;
  List<_Curso> _cursos = [];
  int? _cursoId;
  bool _cargandoCursos = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _soloLogros = _esPreescolar(widget.estudiante.grado);
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    final sesion = AuthService().sesionActual;
    if (sesion == null) {
      setState(() => _cargandoCursos = false);
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
        _cursoId = _cursos.isNotEmpty ? _cursos.first.id : null;
      }
    } catch (_) {}

    if (mounted) setState(() => _cargandoCursos = false);
  }

  @override
  void dispose() {
    _logroC.dispose();
    _notaC.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cursoId == null) return;

    final nota = double.tryParse(_notaC.text.replaceAll(',', '.'));
    if (nota == null || nota < 0 || nota > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una nota válida entre 0.0 y 5.0')),
      );
      return;
    }

    setState(() => _guardando = true);

    final curso = _cursos.firstWhere((c) => c.id == _cursoId);

    final error = await EvaluacionService().agregar(
      estudianteId: widget.estudiante.id,
      cursoId: curso.id,
      cursoTitulo: curso.title,
      periodo: _periodo,
      score: nota,
      logro: _logroC.text.trim(),
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
                Text(
                  'Registro · ${widget.estudiante.nombres}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _soloLogros
                        ? Colors.teal.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _soloLogros
                        ? '🌱 Preescolar — Notas numéricas'
                        : '📚 Primaria — Notas numéricas',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _soloLogros ? Colors.teal : AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                if (_cargandoCursos)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ))
                else if (_cursos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No tienes cursos asignados todavía.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                else ...[
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: _cursos.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
                    onChanged: (v) => setState(() => _cursoId = v ?? _cursoId),
                  ),
                  const SizedBox(height: 12),
                  const Text('PERIODO',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _periodo,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF3F4F7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: periodosValidos.map((p) => DropdownMenuItem(value: p, child: Text('Periodo $p'))).toList(),
                    onChanged: (v) => setState(() => _periodo = v ?? _periodo),
                  ),
                  const SizedBox(height: 12),
                  LabeledTextField(
                    controller: _notaC,
                    label: 'Nota (0.0 a 5.0)',
                    hint: 'Ej. 4.5',
                    icon: Icons.grade_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la nota' : null,
                  ),
                  const SizedBox(height: 12),
                  LabeledTextField(
                    controller: _logroC,
                    label: _soloLogros ? 'Logro' : 'Observación (opcional)',
                    hint: _soloLogros ? 'Describe el logro del estudiante' : 'Comentario sobre el desempeño',
                    icon: Icons.emoji_events_rounded,
                    validator: _soloLogros
                        ? (v) => (v == null || v.trim().isEmpty) ? 'Describe el logro' : null
                        : null,
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
