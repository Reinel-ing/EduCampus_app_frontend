import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/alerta_alumno.dart';
import '../../models/estudiante.dart';
import '../../services/servicio_alertas.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class SituacionAlumnoScreen extends StatefulWidget {
  const SituacionAlumnoScreen({super.key});

  @override
  State<SituacionAlumnoScreen> createState() => _SituacionAlumnoScreenState();
}

class _SituacionAlumnoScreenState extends State<SituacionAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _docenteController = TextEditingController();

  Student? _estudianteSeleccionado;
  List<Student> _resultados = [];
  NivelAlerta _nivel = NivelAlerta.informativo;

  @override
  void initState() {
    super.initState();
    if (StudentService().students.isEmpty) {
      StudentService().cargarDesdeBackend();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descripcionController.dispose();
    _docenteController.dispose();
    super.dispose();
  }

  void _buscar(String query) {
    setState(() => _resultados = StudentService().searchByName(query));
  }

  void _seleccionar(Student s) {
    setState(() {
      _estudianteSeleccionado = s;
      _resultados = [];
      _searchController.text = s.nombreCompleto;
    });
  }

  bool _enviando = false;

  Future<void> _reportar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_estudianteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un estudiante primero')),
      );
      return;
    }

    setState(() => _enviando = true);

    final error = await AlertasService().agregar(
      estudianteId: _estudianteSeleccionado!.id,
      estudianteNombre: _estudianteSeleccionado!.nombreCompleto,
      grado: _estudianteSeleccionado!.grado,
      docenteNombre: _docenteController.text.trim().isEmpty
          ? 'Docente'
          : _docenteController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      nivel: _nivel,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta reportada al administrador')),
    );

    setState(() {
      _enviando = false;
      _estudianteSeleccionado = null;
      _searchController.clear();
      _descripcionController.clear();
      _docenteController.clear();
      _resultados = [];
      _nivel = NivelAlerta.informativo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reportar situación de alumno',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            const Text(
              'Esta alerta llegará directamente al administrador.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 24),

            LabeledTextField(
              controller: _docenteController,
              label: 'Tu nombre',
              hint: 'Nombre del docente',
              icon: Icons.badge_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            const Text(
              'BUSCAR ESTUDIANTE',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _searchController,
              onChanged: _buscar,
              decoration: InputDecoration(
                hintText: 'Escribe el nombre del estudiante',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF3F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_resultados.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E6)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: _resultados.map((s) => ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: Text(s.nombreCompleto),
                    subtitle: Text(s.grado),
                    onTap: () => _seleccionar(s),
                  )).toList(),
                ),
              ),
            if (_estudianteSeleccionado != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_estudianteSeleccionado!.nombreCompleto,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(_estudianteSeleccionado!.grado,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        _estudianteSeleccionado = null;
                        _searchController.clear();
                      }),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text(
              'NIVEL DE ALERTA',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            SegmentedButton<NivelAlerta>(
              segments: const [
                ButtonSegment(
                  value: NivelAlerta.informativo,
                  label: Text('Informativo'),
                  icon: Icon(Icons.info_rounded),
                ),
                ButtonSegment(
                  value: NivelAlerta.seguimiento,
                  label: Text('Seguimiento'),
                  icon: Icon(Icons.visibility_rounded),
                ),
                ButtonSegment(
                  value: NivelAlerta.urgente,
                  label: Text('Urgente'),
                  icon: Icon(Icons.warning_rounded),
                ),
              ],
              selected: {_nivel},
              onSelectionChanged: (v) => setState(() => _nivel = v.first),
            ),

            const SizedBox(height: 20),
            LabeledTextField(
              controller: _descripcionController,
              label: 'Descripción de la situación',
              hint: 'Describe con detalle lo que observaste',
              icon: Icons.notes_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa una descripción' : null,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _reportar,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_enviando ? 'Enviando...' : 'Reportar al administrador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}