import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/formulario.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_formularios.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class _CampoEditable {
  final String id;
  final TextEditingController etiqueta;
  OrigenDato origen;
  String? campoPersonalizadoId;

  _CampoEditable({
    required this.id,
    String texto = '',
    this.origen = OrigenDato.manual,
    this.campoPersonalizadoId,
  }) : etiqueta = TextEditingController(text: texto);
}

class EditorFormularioScreen extends StatefulWidget {
  final PlantillaFormulario? plantilla;
  const EditorFormularioScreen({super.key, this.plantilla});

  @override
  State<EditorFormularioScreen> createState() => _EditorFormularioScreenState();
}

class _EditorFormularioScreenState extends State<EditorFormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  final List<_CampoEditable> _campos = [];

  @override
  void initState() {
    super.initState();
    final p = widget.plantilla;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    if (p != null) {
      for (final c in p.campos) {
        _campos.add(_CampoEditable(
          id: c.id,
          texto: c.etiqueta,
          origen: c.origen,
          campoPersonalizadoId: c.campoPersonalizadoId,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    for (final c in _campos) {
      c.etiqueta.dispose();
    }
    super.dispose();
  }

  void _agregarCampo() {
    setState(() => _campos.add(_CampoEditable(id: FormulariosService.nuevoId())));
  }

  void _quitarCampo(int index) {
    final c = _campos.removeAt(index);
    setState(() {});
    c.etiqueta.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_campos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un campo')),
      );
      return;
    }

    final plantilla = PlantillaFormulario(
      id: widget.plantilla?.id ?? FormulariosService.nuevoId(),
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      campos: [
        for (final c in _campos)
          CampoFormulario(
            id: c.id,
            etiqueta: c.etiqueta.text.trim(),
            origen: c.origen,
            campoPersonalizadoId:
                c.origen == OrigenDato.personalizado ? c.campoPersonalizadoId : null,
          ),
      ],
    );
    FormulariosService().guardar(plantilla);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final personalizados = StudentService().customFields;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.plantilla == null
            ? 'Nuevo formulario'
            : 'Editar formulario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _decoracionTarjeta(),
                    child: Column(
                      children: [
                        LabeledTextField(
                          controller: _nombre,
                          label: 'Nombre del formulario',
                          hint: 'Ej: Matrícula, Seguro escolar, Carnet',
                          icon: Icons.description_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        LabeledTextField(
                          controller: _descripcion,
                          label: 'Descripción (opcional)',
                          hint: 'Para qué se usa este formulario',
                          icon: Icons.notes_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Campos del formulario',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text(
                    'Escribe cómo se llama cada dato y elige de dónde se llena al buscar un estudiante.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < _campos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _filaCampo(i, personalizados),
                    ),
                  OutlinedButton.icon(
                    onPressed: _agregarCampo,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Agregar campo'),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Guardar formulario'),
                      ),
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

  BoxDecoration _decoracionTarjeta() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      );

  Widget _filaCampo(int index, List<dynamic> personalizados) {
    final campo = _campos[index];
    final campoPersonalizadoValido =
        personalizados.any((f) => f.id == campo.campoPersonalizadoId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracionTarjeta(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth >= 600;

          final etiqueta = LabeledTextField(
            controller: campo.etiqueta,
            label: 'Nombre del campo',
            hint: 'Ej: Nombre del estudiante',
            icon: Icons.label_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          );

          final origen = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SE LLENA CON',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6)),
              const SizedBox(height: 6),
              DropdownButtonFormField<OrigenDato>(
                initialValue: campo.origen,
                isExpanded: true,
                decoration: _decoracionDropdown(),
                items: [
                  for (final o in OrigenDato.values)
                    if (o != OrigenDato.personalizado ||
                        personalizados.isNotEmpty)
                      DropdownMenuItem(value: o, child: Text(o.etiqueta)),
                ],
                onChanged: (v) => setState(() {
                  campo.origen = v ?? OrigenDato.manual;
                  if (campo.origen == OrigenDato.personalizado &&
                      !campoPersonalizadoValido &&
                      personalizados.isNotEmpty) {
                    campo.campoPersonalizadoId = personalizados.first.id;
                  }
                }),
              ),
              if (campo.origen == OrigenDato.personalizado &&
                  personalizados.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue:
                      campoPersonalizadoValido ? campo.campoPersonalizadoId : null,
                  isExpanded: true,
                  decoration: _decoracionDropdown(),
                  hint: const Text('Elige el campo'),
                  items: [
                    for (final f in personalizados)
                      DropdownMenuItem<String>(
                          value: f.id as String, child: Text(f.label as String)),
                  ],
                  validator: (v) => v == null ? 'Elige un campo' : null,
                  onChanged: (v) =>
                      setState(() => campo.campoPersonalizadoId = v),
                ),
              ],
            ],
          );

          final borrar = IconButton(
            tooltip: 'Quitar campo',
            onPressed: () => _quitarCampo(index),
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
          );

          if (ancho) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: etiqueta),
                const SizedBox(width: 16),
                Expanded(child: origen),
                Padding(
                    padding: const EdgeInsets.only(top: 20), child: borrar),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              etiqueta,
              const SizedBox(height: 14),
              origen,
              Align(alignment: Alignment.centerRight, child: borrar),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _decoracionDropdown() => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );
}
