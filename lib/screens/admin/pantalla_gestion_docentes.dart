import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/docente.dart';
import '../../services/servicio_admin.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_docentes.dart';

class GestionDocentesScreen extends StatefulWidget {
  const GestionDocentesScreen({super.key});

  @override
  State<GestionDocentesScreen> createState() => _GestionDocentesScreenState();
}

class _GestionDocentesScreenState extends State<GestionDocentesScreen> {
  @override
  void initState() {
    super.initState();
    TeacherService().cargarDesdeBackend();
  }

  void _abrirFormulario(BuildContext context, {Teacher? docente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormularioDocente(docente: docente),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = TeacherService();
    return Stack(
      children: [
        ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final docentes = service.teachers;
            if (docentes.isEmpty) {
              return Center(
                child: Text(
                  service.cargando ? 'Cargando docentes...' : 'Sin docentes registrados',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: docentes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final d = docentes[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7EC)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        d.nombres.isNotEmpty ? d.nombres[0].toUpperCase() : '?',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(d.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${d.especialidad} · ${d.correo}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _abrirFormulario(context, docente: d),
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
            label: const Text('Registrar'),
          ),
        ),
      ],
    );
  }
}

class _FormularioDocente extends StatefulWidget {
  final Teacher? docente;
  const _FormularioDocente({this.docente});

  @override
  State<_FormularioDocente> createState() => _FormularioDocenteState();
}

class _FormularioDocenteState extends State<_FormularioDocente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _documentoCtrl;
  late final TextEditingController _especialidadCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _correoCtrl;
  bool _isLoading = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    final d = widget.docente;
    _nombresCtrl = TextEditingController(text: d?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: d?.apellidos ?? '');
    _documentoCtrl = TextEditingController(text: d?.documento ?? '');
    _especialidadCtrl = TextEditingController(text: d?.especialidad ?? '');
    _telefonoCtrl = TextEditingController(text: d?.telefono ?? '');
    _correoCtrl = TextEditingController(text: d?.correo ?? '');
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _documentoCtrl.dispose();
    _especialidadCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final service = TeacherService();
    final isNew = widget.docente == null;

    if (!isNew) {
      final teacher = Teacher(
        id: widget.docente!.id,
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        documento: _documentoCtrl.text.trim(),
        especialidad: _especialidadCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        contrasena: widget.docente!.contrasena,
        gradosAsignados: widget.docente?.gradosAsignados,
      );
      service.updateTeacher(teacher);
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final contrasena = generarPasswordSegura();

    try {
      final cuenta = await AdminService().registrarUsuario(
        nombre: '${_nombresCtrl.text.trim()} ${_apellidosCtrl.text.trim()}',
        correo: _correoCtrl.text.trim(),
        password: contrasena,
        rol: 'profesor',
        especialidad: _especialidadCtrl.text.trim(),
      );

      final teacher = Teacher(
        id: cuenta.id.toString(),
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        documento: _documentoCtrl.text.trim(),
        especialidad: _especialidadCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        correo: cuenta.correo,
        contrasena: contrasena,
      );

      service.addTeacher(teacher);

      if (!mounted) return;

      // El formulario se cierra: el diálogo usa el contexto del navegador raíz.
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      Navigator.pop(context);
      showDialog(
        context: rootContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Docente registrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nombre: ${teacher.nombreCompleto}'),
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

  void _restablecerPassword() async {
    final docente = widget.docente;
    if (docente == null) return;

    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final nuevaContrasena = generarPasswordSegura();

    try {
      await AdminService().restablecerPassword(
        correo: docente.correo,
        rol: 'profesor',
        password: nuevaContrasena,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Contraseña restablecida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Docente: ${docente.nombreCompleto}'),
              Text('Correo: ${docente.correo}'),
              const SizedBox(height: 8),
              const Text('Nueva contraseña:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(8)),
                child: Text(nuevaContrasena, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold)),
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
  Widget build(BuildContext context) {
    final isNew = widget.docente == null;
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNew ? 'Registrar docente' : 'Editar docente',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              _campo(_nombresCtrl, 'Nombres', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _campo(_apellidosCtrl, 'Apellidos', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _campo(_documentoCtrl, 'Documento', Icons.badge_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _campo(_especialidadCtrl, 'Especialidad', Icons.school_outlined),
              const SizedBox(height: 14),
              _campo(_telefonoCtrl, 'Teléfono', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _campo(_correoCtrl, 'Correo (@gmail.com)', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              if (_errorMensaje != null) ...[
                const SizedBox(height: 14),
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
              if (!isNew) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _restablecerPassword,
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: const Text('Restablecer contraseña'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(isNew ? 'Registrar' : 'Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF3F4F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null : null,
    );
  }
}