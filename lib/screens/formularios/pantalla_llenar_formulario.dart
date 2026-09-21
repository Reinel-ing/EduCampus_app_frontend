import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../models/formulario.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class _CampoLleno {
  final String etiqueta;
  final CampoFormulario? definicion; // null si es un campo extra
  final TextEditingController controller = TextEditingController();

  _CampoLleno(this.etiqueta, this.definicion);
}

class LlenarFormularioScreen extends StatefulWidget {
  final PlantillaFormulario plantilla;
  const LlenarFormularioScreen({super.key, required this.plantilla});

  @override
  State<LlenarFormularioScreen> createState() => _LlenarFormularioScreenState();
}

class _LlenarFormularioScreenState extends State<LlenarFormularioScreen> {
  final _busqueda = TextEditingController();
  final _focoBusqueda = FocusNode();
  late final List<_CampoLleno> _campos;
  Student? _seleccionado;

  @override
  void initState() {
    super.initState();
    _campos = [
      for (final c in widget.plantilla.campos) _CampoLleno(c.etiqueta, c),
    ];
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _focoBusqueda.dispose();
    for (final c in _campos) {
      c.controller.dispose();
    }
    super.dispose();
  }

  void _seleccionar(Student s) {
    setState(() {
      _seleccionado = s;
      for (final c in _campos) {
        final def = c.definicion;
        if (def != null && def.origen != OrigenDato.manual) {
          c.controller.text = def.valorPara(s);
        }
      }
    });
  }

  void _limpiar() {
    setState(() {
      _seleccionado = null;
      _busqueda.clear();
      for (final c in _campos) {
        c.controller.clear();
      }
    });
  }

  Future<void> _agregarCampoExtra() async {
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar campo'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre del campo'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Agregar')),
        ],
      ),
    );
    ctrl.dispose();
    if (nombre == null || nombre.isEmpty) return;
    setState(() => _campos.add(_CampoLleno(nombre, null)));
  }

  void _quitarExtra(_CampoLleno campo) {
    setState(() => _campos.remove(campo));
    campo.controller.dispose();
  }

  Future<void> _copiar() async {
    final texto = _campos
        .map((c) => '${c.etiqueta}: ${c.controller.text.trim()}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos copiados al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = StudentService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.plantilla.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tarjeta(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BUSCAR ESTUDIANTE',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      RawAutocomplete<Student>(
                        textEditingController: _busqueda,
                        focusNode: _focoBusqueda,
                        displayStringForOption: (s) => s.nombreCompleto,
                        optionsBuilder: (v) => service.searchByName(v.text),
                        onSelected: _seleccionar,
                        fieldViewBuilder: (context, ctrl, foco, _) =>
                            TextField(
                          controller: ctrl,
                          focusNode: foco,
                          decoration: InputDecoration(
                            hintText: 'Escribe el nombre del estudiante',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        optionsViewBuilder: (context, onSelected, options) =>
                            Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: 500, maxHeight: 240),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: [
                                  for (final s in options)
                                    ListTile(
                                      dense: true,
                                      leading: const Icon(
                                          Icons.person_rounded, size: 20),
                                      title: Text(s.nombreCompleto),
                                      subtitle: Text(s.grado),
                                      onTap: () => onSelected(s),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (service.students.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Aún no hay estudiantes registrados.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                      if (_seleccionado != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 18, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Datos de ${_seleccionado!.nombreCompleto} cargados. Puedes editarlos antes de copiar.',
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _tarjeta(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dosColumnas = constraints.maxWidth >= 560;
                      final ancho = dosColumnas
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final c in _campos)
                            SizedBox(
                              width: ancho,
                              child: Stack(
                                children: [
                                  LabeledTextField(
                                    controller: c.controller,
                                    label: c.etiqueta,
                                    hint: c.definicion == null
                                        ? 'Campo adicional'
                                        : c.definicion!.origen ==
                                                OrigenDato.manual
                                            ? 'Escribe aquí'
                                            : 'Se llena al elegir estudiante',
                                    icon: c.definicion == null
                                        ? Icons.add_circle_outline_rounded
                                        : Icons.text_fields_rounded,
                                  ),
                                  if (c.definicion == null)
                                    Positioned(
                                      right: 0,
                                      top: -8,
                                      child: IconButton(
                                        tooltip: 'Quitar campo',
                                        iconSize: 18,
                                        onPressed: () => _quitarExtra(c),
                                        icon: const Icon(Icons.close_rounded,
                                            color: AppColors.danger),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _agregarCampoExtra,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agregar otro campo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _limpiar,
                      icon: const Icon(Icons.cleaning_services_rounded,
                          size: 18),
                      label: const Text('Limpiar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _copiar,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar datos'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E7EC)),
        ),
        child: child,
      );
}
