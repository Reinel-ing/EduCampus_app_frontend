// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../models/registro_academico.dart';
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

// ─── Boletín PDF ─────────────────────────────────────────────────────────────

Future<void> _generarBoletin(
    Student estudiante, List<RegistroAcademico> registros) async {
  final doc = pw.Document();
  final preescolar = _esPreescolar(estudiante.grado);
  final hoy = DateTime.now();
  final fechaStr =
      '${hoy.day.toString().padLeft(2, '0')}/${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';

  // Agrupa registros por materia
  final Map<String, List<RegistroAcademico>> porMateria = {};
  for (final r in registros) {
    porMateria.putIfAbsent(r.materia, () => []).add(r);
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context ctx) => [
        // ── Encabezado ──
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF1E3A6E),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'COLEGIO MANANTIAL DE SABIDURÍA',
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 15,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'COLMAS — Sistema EduCampus',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey300),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                preescolar
                    ? 'BOLETÍN DE DESEMPEÑO — PREESCOLAR'
                    : 'BOLETÍN DE CALIFICACIONES — PRIMARIA',
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 13,
                  color: PdfColors.yellow,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // ── Info estudiante ──
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Estudiante:',
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                          font: pw.Font.helveticaBold())),
                  pw.SizedBox(height: 2),
                  pw.Text(estudiante.nombreCompleto,
                      style: pw.TextStyle(
                          fontSize: 13, font: pw.Font.helveticaBold())),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Grado: ${estudiante.grado}',
                      style: pw.TextStyle(
                          fontSize: 11, font: pw.Font.helveticaBold())),
                  pw.SizedBox(height: 2),
                  pw.Text('Fecha: $fechaStr',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // ── Contenido según nivel ──
        if (porMateria.isEmpty)
          pw.Center(
            child: pw.Text('Sin registros académicos aún.',
                style: pw.TextStyle(color: PdfColors.grey600)),
          )
        else
          ...porMateria.entries.map((entry) {
            final materia = entry.key;
            final regs = entry.value;
            final notas = regs
                .where((r) =>
                    r.tipo == TipoRegistroAcademico.nota &&
                    r.calificacion != null)
                .toList();
            final logros =
                regs.where((r) => r.tipo == TipoRegistroAcademico.logro).toList();
            final obs = regs
                .where((r) => r.tipo == TipoRegistroAcademico.observacion)
                .toList();
            final promedio = notas.isEmpty
                ? null
                : notas.map((r) => r.calificacion!).reduce((a, b) => a + b) /
                    notas.length;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: const PdfColor.fromInt(0xFFEEF2FF),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(materia.toUpperCase(),
                          style: pw.TextStyle(
                              font: pw.Font.helveticaBold(),
                              fontSize: 11,
                              color: const PdfColor.fromInt(0xFF1E3A6E))),
                      if (!preescolar && promedio != null)
                        pw.Text(
                          'Promedio: ${promedio.toStringAsFixed(1)}',
                          style: pw.TextStyle(
                            font: pw.Font.helveticaBold(),
                            fontSize: 11,
                            color: promedio >= 3.0
                                ? PdfColors.green700
                                : PdfColors.red700,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                if (!preescolar) ...[
                  if (notas.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
                      child: pw.Text('Sin notas registradas.',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                    )
                  else
                    ...notas.map((r) => pw.Padding(
                          padding: const pw.EdgeInsets.only(
                              left: 12, bottom: 3),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                  child: pw.Text(r.titulo,
                                      style:
                                          const pw.TextStyle(fontSize: 10))),
                              pw.Text(
                                r.calificacion!.toStringAsFixed(1),
                                style: pw.TextStyle(
                                  font: pw.Font.helveticaBold(),
                                  fontSize: 10,
                                  color: r.calificacion! >= 3.0
                                      ? PdfColors.green700
                                      : PdfColors.red700,
                                ),
                              ),
                            ],
                          ),
                        )),
                ] else ...[
                  if (logros.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
                      child: pw.Text('Sin logros registrados.',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600)),
                    )
                  else
                    ...logros.map((r) => pw.Padding(
                          padding: const pw.EdgeInsets.only(
                              left: 12, bottom: 3),
                          child: pw.Row(
                            children: [
                              pw.Text('✓ ',
                                  style: pw.TextStyle(
                                      color: PdfColors.green700,
                                      fontSize: 10)),
                              pw.Expanded(
                                  child: pw.Text(r.titulo,
                                      style:
                                          const pw.TextStyle(fontSize: 10))),
                            ],
                          ),
                        )),
                ],
                if (obs.isNotEmpty) ...[
                  ...obs.map((r) => pw.Padding(
                        padding:
                            const pw.EdgeInsets.only(left: 12, bottom: 3),
                        child: pw.Row(
                          children: [
                            pw.Text('📝 ',
                                style: const pw.TextStyle(fontSize: 10)),
                            pw.Expanded(
                              child: pw.Text(r.titulo,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.grey700)),
                            ),
                          ],
                        ),
                      )),
                ],
                pw.SizedBox(height: 10),
              ],
            );
          }),

        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Text(
          'Generado por EduCampus — COLMAS  ·  $fechaStr',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute(
        'download', 'boletin_${estudiante.nombreCompleto.replaceAll(' ', '_')}.pdf')
    ..click();
  html.Url.revokeObjectUrl(url);
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
    if (StudentService().students.isEmpty) {
      StudentService().cargarDesdeBackend();
    }
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
    final cantLogros =
        registros.where((r) => r.tipo == TipoRegistroAcademico.logro).length;

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
          ListenableBuilder(
            listenable: service,
            builder: (context, _) {
              final registros = service.porEstudiante(estudiante.id);
              return IconButton(
                tooltip: 'Descargar boletín PDF',
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.danger),
                onPressed: () => _generarBoletin(estudiante, registros),
              );
            },
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
                          if (r.tipo == TipoRegistroAcademico.nota &&
                              r.calificacion != null)
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _colorPromedio(r.calificacion!)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                r.calificacion!.toStringAsFixed(1),
                                style: TextStyle(
                                    color: _colorPromedio(r.calificacion!),
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: (r.tipo == TipoRegistroAcademico.logro
                                        ? Colors.teal
                                        : AppColors.primary)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                r.tipo == TipoRegistroAcademico.logro
                                    ? Icons.emoji_events_rounded
                                    : Icons.visibility_rounded,
                                color:
                                    r.tipo == TipoRegistroAcademico.logro
                                        ? Colors.teal
                                        : AppColors.primary,
                                size: 20,
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
                                      child: Text(r.titulo,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Text(r.tipo.etiqueta,
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(r.materia,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5)),
                                if (r.descripcion.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r.descripcion,
                                      style:
                                          const TextStyle(fontSize: 13.5)),
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

class _FormularioRegistro extends StatefulWidget {
  final Student estudiante;
  const _FormularioRegistro({required this.estudiante});

  @override
  State<_FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<_FormularioRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _materiaC = TextEditingController();
  final _tituloC = TextEditingController();
  final _descC = TextEditingController();
  final _calificacionC = TextEditingController();

  late TipoRegistroAcademico _tipo;
  late bool _soloLogros;

  @override
  void initState() {
    super.initState();
    _soloLogros = _esPreescolar(widget.estudiante.grado);
    _tipo = _soloLogros
        ? TipoRegistroAcademico.logro
        : TipoRegistroAcademico.nota;
  }

  @override
  void dispose() {
    _materiaC.dispose();
    _tituloC.dispose();
    _descC.dispose();
    _calificacionC.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    double? calificacion;
    if (_tipo == TipoRegistroAcademico.nota) {
      calificacion =
          double.tryParse(_calificacionC.text.replaceAll(',', '.'));
    }
    EvaluacionService().agregar(
      estudianteId: widget.estudiante.id,
      materia: _materiaC.text.trim(),
      tipo: _tipo,
      titulo: _tituloC.text.trim(),
      descripcion: _descC.text.trim(),
      calificacion: calificacion,
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
                        ? '🌱 Preescolar — Solo logros y observaciones'
                        : '📚 Primaria — Notas numéricas',
                    style: TextStyle(
                      fontSize: 12,
                      color: _soloLogros ? Colors.teal : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tipo de registro
                if (_soloLogros)
                  SegmentedButton<TipoRegistroAcademico>(
                    segments: const [
                      ButtonSegment(
                          value: TipoRegistroAcademico.logro,
                          label: Text('Logro'),
                          icon: Icon(Icons.emoji_events_rounded)),
                      ButtonSegment(
                          value: TipoRegistroAcademico.observacion,
                          label: Text('Observación'),
                          icon: Icon(Icons.visibility_rounded)),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (n) =>
                        setState(() => _tipo = n.first),
                  )
                else
                  SegmentedButton<TipoRegistroAcademico>(
                    segments: const [
                      ButtonSegment(
                          value: TipoRegistroAcademico.nota,
                          label: Text('Nota'),
                          icon: Icon(Icons.grade_rounded)),
                      ButtonSegment(
                          value: TipoRegistroAcademico.observacion,
                          label: Text('Obs.'),
                          icon: Icon(Icons.visibility_rounded)),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (n) =>
                        setState(() => _tipo = n.first),
                  ),
                const SizedBox(height: 16),
                LabeledTextField(
                  controller: _materiaC,
                  label: 'Materia / Área',
                  hint: 'Ej. Matemáticas',
                  icon: Icons.menu_book_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa la materia'
                      : null,
                ),
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _tituloC,
                  label: _tipo == TipoRegistroAcademico.nota
                      ? 'Actividad evaluada'
                      : _tipo == TipoRegistroAcademico.logro
                          ? 'Descripción del logro'
                          : 'Observación',
                  hint: _tipo == TipoRegistroAcademico.nota
                      ? 'Ej. Evaluación unidad 2'
                      : _tipo == TipoRegistroAcademico.logro
                          ? 'Ej. Identifica patrones numéricos'
                          : 'Ej. Muestra interés por la lectura',
                  icon: Icons.edit_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el texto'
                      : null,
                ),
                if (_tipo == TipoRegistroAcademico.nota) ...[
                  const SizedBox(height: 12),
                  LabeledTextField(
                    controller: _calificacionC,
                    label: 'Calificación (1.0 - 5.0)',
                    hint: 'Ej. 4.5',
                    icon: Icons.numbers_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      final valor = double.tryParse(
                          (v ?? '').replaceAll(',', '.'));
                      if (valor == null) return 'Número no válido';
                      if (valor < 1.0 || valor > 5.0) {
                        return 'Debe estar entre 1.0 y 5.0';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                LabeledTextField(
                  controller: _descC,
                  label: 'Detalles adicionales (opcional)',
                  hint: 'Comentarios extra',
                  icon: Icons.notes_rounded,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Guardar'),
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