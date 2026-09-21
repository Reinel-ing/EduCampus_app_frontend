import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/campo_personalizado.dart';
import '../../models/estudiante.dart';
import '../../models/acudiente_cuenta.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_grados.dart';
import '../../services/servicio_acudientes.dart';
import '../../services/servicio_admin.dart';
import '../../services/servicio_auth.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class FormularioEstudianteScreen extends StatefulWidget {
  final Student? estudiante;

  const FormularioEstudianteScreen({super.key, this.estudiante});

  @override
  State<FormularioEstudianteScreen> createState() => _FormularioEstudianteScreenState();
}

class _FormularioEstudianteScreenState extends State<FormularioEstudianteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StudentService();

  final _searchController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();
  final _fechaNacController = TextEditingController();

  final Map<String, TextEditingController> _customControllers = {};

  String? _gradoSeleccionado;
  String? _acudienteIdSeleccionado;
  String? _idEnEdicion;
  List<Student> _resultadosBusqueda = [];
  bool _isLoading = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _syncCustomControllers();
    GradoService().cargarDesdeBackend();
    AcudientesService().cargarDesdeBackend().then((_) {
      if (!mounted || widget.estudiante == null) return;
      _vincularAcudientePorCorreo(widget.estudiante!.acudienteCorreo);
    });
    if (widget.estudiante != null) {
      _cargarEstudiante(widget.estudiante!);
    }
  }

  void _vincularAcudientePorCorreo(String correo) {
    if (correo.trim().isEmpty) return;
    for (final c in AcudientesService().cuentas) {
      if (c.correo.trim().toLowerCase() == correo.trim().toLowerCase()) {
        setState(() => _acudienteIdSeleccionado = c.id);
        return;
      }
    }
  }

  AcudienteCuenta? _buscarAcudienteSeleccionado() {
    if (_acudienteIdSeleccionado == null) return null;
    for (final c in AcudientesService().cuentas) {
      if (c.id == _acudienteIdSeleccionado) return c;
    }
    return null;
  }

  void _syncCustomControllers() {
    for (final field in _service.customFields) {
      _customControllers.putIfAbsent(field.id, () => TextEditingController());
    }
  }

  void _cargarEstudiante(Student s) {
    _idEnEdicion = s.id;
    _nombresController.text = s.nombres;
    _apellidosController.text = s.apellidos;
    _fechaNacController.text = s.fechaNacimiento;
    _gradoSeleccionado = s.grado;
    for (final entry in s.camposPersonalizados.entries) {
      _customControllers[entry.key]?.text = entry.value;
    }
  }

  void _buscar(String query) {
    setState(() => _resultadosBusqueda = _service.searchByName(query));
  }

  void _seleccionarResultado(Student s) {
    setState(() {
      _cargarEstudiante(s);
      _resultadosBusqueda = [];
      _searchController.clear();
    });
  }

  void _agregarCampoPersonalizado() async {
    final labelCtrl = TextEditingController();
    final opcionesCtrl = TextEditingController();
    TipoCampo tipoSeleccionado = TipoCampo.texto;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo campo personalizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: labelCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre del campo',
                  hintText: 'Ej: EPS, Tipo de sangre, Alergias...',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<TipoCampo>(
                initialValue: tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de dato'),
                items: const [
                  DropdownMenuItem(value: TipoCampo.texto, child: Text('Texto')),
                  DropdownMenuItem(value: TipoCampo.numero, child: Text('Número')),
                  DropdownMenuItem(value: TipoCampo.fecha, child: Text('Fecha')),
                  DropdownMenuItem(value: TipoCampo.seleccion, child: Text('Lista de opciones')),
                ],
                onChanged: (v) => setDialogState(() => tipoSeleccionado = v ?? tipoSeleccionado),
              ),
              if (tipoSeleccionado == TipoCampo.seleccion) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: opcionesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Opciones separadas por coma',
                    hintText: 'Ej: Sí, No, En proceso',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agregar')),
          ],
        ),
      ),
    );

    if (confirmado == true && labelCtrl.text.trim().isNotEmpty) {
      final opciones = opcionesCtrl.text
          .split(',')
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList();
      setState(() {
        _service.addCustomField(labelCtrl.text.trim(), tipo: tipoSeleccionado, opciones: opciones);
        _syncCustomControllers();
      });
    }
  }

  Widget _construirCampoPersonalizado(CustomField field) {
    final controller = _customControllers[field.id]!;
    switch (field.tipo) {
      case TipoCampo.numero:
        return LabeledTextField(
          controller: controller,
          label: field.label,
          hint: field.label,
          icon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
        );
      case TipoCampo.fecha:
        return GestureDetector(
          onTap: () async {
            final fecha = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1990),
              lastDate: DateTime(2100),
            );
            if (fecha != null) {
              setState(() {
                controller.text =
                    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
              });
            }
          },
          child: AbsorbPointer(
            child: LabeledTextField(
              controller: controller,
              label: field.label,
              hint: 'DD/MM/AAAA',
              icon: Icons.calendar_today_rounded,
            ),
          ),
        );
      case TipoCampo.seleccion:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: controller.text.isNotEmpty ? controller.text : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              hint: Text(field.label),
              items: field.opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (v) => setState(() => controller.text = v ?? ''),
            ),
          ],
        );
      case TipoCampo.texto:
        return LabeledTextField(
          controller: controller,
          label: field.label,
          hint: field.label,
          icon: Icons.edit_note_rounded,
        );
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gradoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un grado')),
      );
      return;
    }

    final camposPersonalizados = <String, String>{};
    for (final field in _service.customFields) {
      camposPersonalizados[field.id] = _customControllers[field.id]?.text ?? '';
    }
    final acudienteSeleccionado = _buscarAcudienteSeleccionado();

    if (_idEnEdicion != null) {
      final estudiante = Student(
        id: _idEnEdicion!,
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        fechaNacimiento: _fechaNacController.text.trim(),
        grado: _gradoSeleccionado!,
        acudienteNombre: acudienteSeleccionado?.nombre ?? '',
        acudienteTelefono: acudienteSeleccionado?.telefono ?? '',
        acudienteParentesco: '',
        acudienteCorreo: acudienteSeleccionado?.correo ?? '',
        camposPersonalizados: camposPersonalizados,
      );
      _service.updateStudent(estudiante);
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final gradoId = GradoService().idPorNombre(_gradoSeleccionado!);
    final acudienteId = _acudienteIdSeleccionado == null ? null : int.tryParse(_acudienteIdSeleccionado!);
    final contrasena = generarPasswordSegura();

    try {
      final cuenta = await AdminService().registrarUsuario(
        nombre: '${_nombresController.text.trim()} ${_apellidosController.text.trim()}',
        correo: _correoController.text.trim(),
        password: contrasena,
        rol: 'estudiante',
        gradoId: gradoId,
        acudienteId: acudienteId,
      );

      final estudiante = Student(
        id: cuenta.id.toString(),
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        fechaNacimiento: _fechaNacController.text.trim(),
        grado: _gradoSeleccionado!,
        acudienteNombre: acudienteSeleccionado?.nombre ?? '',
        acudienteTelefono: acudienteSeleccionado?.telefono ?? '',
        acudienteParentesco: '',
        acudienteCorreo: acudienteSeleccionado?.correo ?? '',
        camposPersonalizados: camposPersonalizados,
      );
      _service.addStudent(estudiante);

      if (!mounted) return;

      final rootContext = Navigator.of(context, rootNavigator: true).context;
      Navigator.pop(context);
      showDialog(
        context: rootContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Estudiante registrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nombre: ${estudiante.nombreCompleto}'),
              Text('Correo: ${cuenta.correo}'),
              const SizedBox(height: 8),
              const Text('Contraseña temporal:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(8)),
                child: Text(contrasena, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Listo')),
          ],
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMensaje = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMensaje = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _fechaNacController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_idEnEdicion != null ? 'Editar estudiante' : 'Registrar estudiante'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_idEnEdicion == null) ...[
                const Text(
                  'Buscar estudiante existente',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: _buscar,
                  decoration: InputDecoration(
                    hintText: 'Escribe el nombre para buscar...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_resultadosBusqueda.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E6)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: _resultadosBusqueda.map((s) => ListTile(
                        title: Text(s.nombreCompleto),
                        subtitle: Text(s.grado),
                        onTap: () => _seleccionarResultado(s),
                      )).toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
              ],

              const Text(
                'Datos del estudiante',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 16),

              LabeledTextField(
                controller: _nombresController,
                label: 'Nombres',
                hint: 'Nombres del estudiante',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              LabeledTextField(
                controller: _apellidosController,
                label: 'Apellidos',
                hint: 'Apellidos del estudiante',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              if (_idEnEdicion == null) ...[
                const SizedBox(height: 16),
                LabeledTextField(
                  controller: _correoController,
                  label: 'Correo del estudiante (@gmail.com)',
                  hint: 'estudiante@gmail.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
              ],
              const SizedBox(height: 16),
              LabeledTextField(
                controller: _fechaNacController,
                label: 'Fecha de nacimiento',
                hint: 'DD/MM/AAAA',
                icon: Icons.cake_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'GRADO',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6),
              ),
              const SizedBox(height: 6),
              ListenableBuilder(
                listenable: GradoService(),
                builder: (context, _) {
                  final grados = GradoService().grados;
                  return DropdownButtonFormField<String>(
                    initialValue: grados.contains(_gradoSeleccionado) ? _gradoSeleccionado : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF3F4F7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (value) => setState(() => _gradoSeleccionado = value),
                    validator: (v) => v == null ? 'Selecciona un grado' : null,
                  );
                },
              ),

              const SizedBox(height: 28),
              const Text(
                'Acudiente',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 16),

              ListenableBuilder(
                listenable: AcudientesService(),
                builder: (context, _) {
                  final cuentas = AcudientesService().cuentas;
                  final valorValido = cuentas.any((c) => c.id == _acudienteIdSeleccionado);
                  return DropdownButtonFormField<String>(
                    initialValue: valorValido ? _acudienteIdSeleccionado : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF3F4F7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    hint: const Text('Sin acudiente asignado'),
                    items: cuentas
                        .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nombre} · ${c.correo}')))
                        .toList(),
                    onChanged: (value) => setState(() => _acudienteIdSeleccionado = value),
                  );
                },
              ),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF5C2C0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFC0392B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMensaje!,
                            style: const TextStyle(color: Color(0xFFC0392B), fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],

              if (_service.customFields.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  'Campos adicionales',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ..._service.customFields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _construirCampoPersonalizado(field),
                )),
              ],

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _agregarCampoPersonalizado,
                icon: const Icon(Icons.add),
                label: const Text('Agregar campo personalizado'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(_idEnEdicion != null ? 'Guardar cambios' : 'Registrar estudiante'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}