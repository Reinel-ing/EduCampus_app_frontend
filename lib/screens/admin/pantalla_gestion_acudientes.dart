import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/acudiente_cuenta.dart';
import '../../services/servicio_acudientes.dart';
import '../../services/servicio_admin.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_contrasenas_cache.dart';
import '../../services/servicio_estudiantes.dart';
import '../../widgets/contrasena_copiable.dart';

class GestionAcudientesScreen extends StatefulWidget {
  const GestionAcudientesScreen({super.key});

  @override
  State<GestionAcudientesScreen> createState() => _GestionAcudientesScreenState();
}

class _GestionAcudientesScreenState extends State<GestionAcudientesScreen> {
  @override
  void initState() {
    super.initState();
    AcudientesService().cargarDesdeBackend();
    StudentService().cargarDesdeBackendSiHaceFalta();
  }

  void _abrirFormulario(BuildContext context, {AcudienteCuenta? cuenta}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormularioAcudiente(cuenta: cuenta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AcudientesService();
    return Stack(
      children: [
        ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final cuentas = service.cuentas;
            if (cuentas.isEmpty) {
              return Center(
                child: Text(
                  service.cargando ? 'Cargando acudientes...' : 'Sin cuentas de acudiente registradas',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: cuentas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = cuentas[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7EC)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink.shade50,
                      child: Text(
                        c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?',
                        style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(builder: (context) {
                          final vinculados = StudentService()
                              .students
                              .where((s) => s.acudienteCorreo.trim().toLowerCase() == c.correo.trim().toLowerCase())
                              .length;
                          return Text('${c.correo} · $vinculados estudiante(s)');
                        }),
                        ContrasenaEnLista(
                          contrasena: c.contrasena.isNotEmpty
                              ? c.contrasena
                              : (ContrasenasCache.obtener(c.correo) ?? ''),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _abrirFormulario(context, cuenta: c),
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
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Crear cuenta'),
          ),
        ),
      ],
    );
  }
}

class _FormularioAcudiente extends StatefulWidget {
  final AcudienteCuenta? cuenta;
  const _FormularioAcudiente({this.cuenta});

  @override
  State<_FormularioAcudiente> createState() => _FormularioAcudienteState();
}

class _FormularioAcudienteState extends State<_FormularioAcudiente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  List<String> _estudianteIds = [];
  bool _isLoading = false;
  String? _errorMensaje;
  String? _contrasenaReal;
  bool _consultandoPassword = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cuenta;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _correoCtrl = TextEditingController(text: c?.correo ?? '');
    _telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    _estudianteIds = List<String>.from(c?.estudianteIds ?? []);

    if (c != null) {
      _consultandoPassword = true;
      AdminService().consultarPassword(c.correo).then((valor) {
        if (!mounted) return;
        setState(() {
          _contrasenaReal = valor;
          _consultandoPassword = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final service = AcudientesService();
    final isNew = widget.cuenta == null;

    if (!isNew) {
      widget.cuenta!
        ..nombre = _nombreCtrl.text.trim()
        ..correo = _correoCtrl.text.trim()
        ..telefono = _telefonoCtrl.text.trim()
        ..estudianteIds = _estudianteIds;
      service.actualizar(widget.cuenta!);
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final contrasena = generarPasswordSegura();

    try {
      final cuentaBackend = await AdminService().registrarUsuario(
        nombre: _nombreCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        password: contrasena,
        rol: 'acudiente',
        telefono: _telefonoCtrl.text.trim(),
      );

      final nueva = AcudienteCuenta(
        id: cuentaBackend.id.toString(),
        nombre: cuentaBackend.nombre,
        correo: cuentaBackend.correo,
        telefono: _telefonoCtrl.text.trim(),
        contrasena: contrasena,
        estudianteIds: _estudianteIds,
      );

      service.agregarExistente(nueva);
      ContrasenasCache.guardar(nueva.correo, contrasena);

      if (!mounted) return;

      // El formulario se cierra: el diálogo usa el contexto del navegador raíz.
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      Navigator.pop(context);
      showDialog(
        context: rootContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cuenta creada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acudiente: ${nueva.nombre}'),
              Text('Correo: ${nueva.correo}'),
              const SizedBox(height: 8),
              const Text('Contraseña temporal:', style: TextStyle(fontWeight: FontWeight.bold)),
              ContrasenaCopiable(contrasena: nueva.contrasena),
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
    final cuenta = widget.cuenta;
    if (cuenta == null) return;

    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final nuevaContrasena = generarPasswordSegura();

    try {
      await AdminService().restablecerPassword(
        correo: cuenta.correo,
        rol: 'acudiente',
        password: nuevaContrasena,
      );

      cuenta.contrasena = nuevaContrasena;
      AcudientesService().actualizar(cuenta);
      ContrasenasCache.guardar(cuenta.correo, nuevaContrasena);

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
              Text('Acudiente: ${cuenta.nombre}'),
              Text('Correo: ${cuenta.correo}'),
              const SizedBox(height: 8),
              const Text('Nueva contraseña:', style: TextStyle(fontWeight: FontWeight.bold)),
              ContrasenaCopiable(contrasena: nuevaContrasena),
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
    return ListenableBuilder(
      listenable: StudentService(),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final isNew = widget.cuenta == null;
    final students = StudentService().students;
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNew ? 'Crear cuenta de acudiente' : 'Editar cuenta',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              _campo(_nombreCtrl, 'Nombre completo', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _campo(_correoCtrl, 'Correo (@gmail.com)', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              if (!isNew) ...[
                Builder(builder: (context) {
                  final cuenta = widget.cuenta!;
                  final contrasena = _contrasenaReal ??
                      (cuenta.contrasena.isNotEmpty
                          ? cuenta.contrasena
                          : ContrasenasCache.obtener(cuenta.correo));

                  if (_consultandoPassword && contrasena == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (contrasena == null || contrasena.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contraseña', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ContrasenaEnLista(contrasena: contrasena),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 14),
              _campo(_telefonoCtrl, 'Teléfono', Icons.phone_outlined, keyboardType: TextInputType.phone),
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
                const SizedBox(height: 20),
                const Text('Estudiantes vinculados',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Se vinculan desde el registro del estudiante, no aquí.',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Builder(builder: (context) {
                  final vinculados = students
                      .where((s) => s.acudienteCorreo.trim().toLowerCase() == widget.cuenta!.correo.trim().toLowerCase())
                      .toList();

                  if (vinculados.isEmpty) {
                    return const Text('Ningún estudiante vinculado todavía.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary));
                  }

                  return Column(
                    children: vinculados
                        .map((s) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
                              title: Text(s.nombreCompleto),
                              subtitle: Text(s.grado),
                            ))
                        .toList(),
                  );
                }),
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
                      : Text(isNew ? 'Crear cuenta' : 'Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
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
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
    );
  }
}