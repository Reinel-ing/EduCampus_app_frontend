import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../widgets/campo_texto_etiquetado.dart';
import '../../services/servicio_acudientes.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_instalacion.dart';
import '../admin/panel_admin.dart';
import '../docente/panel_docente.dart';
import '../acudiente/panel_acudiente.dart';
import 'dialogo_recuperar_contrasena.dart';

final _correoRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _verPassword = false;
  String? _errorMensaje;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Construye la pantalla destino según el rol devuelto por el backend.
  /// Devuelve null si el rol no tiene una pantalla propia en esta app.
  Widget? _destinoParaRol(String rol, String correo) {
    switch (rol) {
      case 'administrador':
        return const AdminDashboard();
      case 'profesor':
        return const DocenteDashboard();
      case 'acudiente':
        final acudientes = AcudientesService();
        for (final c in acudientes.cuentas) {
          if (c.correo.trim().toLowerCase() == correo) {
            acudientes.seleccionarCuenta(c.id);
            break;
          }
        }
        return const AcudienteDashboard();
      default:
        return null;
    }
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    final correo = _emailController.text.trim().toLowerCase();

    try {
      final sesion = await AuthService().iniciarSesion(
        correo: correo,
        password: _passwordController.text,
      );

      if (!mounted) return;

      final destino = _destinoParaRol(sesion.rol, correo);

      if (destino == null) {
        setState(() {
          _isLoading = false;
          _errorMensaje = 'Este rol todavía no tiene acceso a la app';
        });
        return;
      }

      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destino),
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

  bool get _mostrarBotonDescargar =>
      kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _descargarApp() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _mostrarInstruccionesIOS();
      return;
    }

    final resultado = await InstalacionService().instalar();

    if (!mounted) return;

    if (resultado == 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Listo! EduCampus se está instalando.')),
      );
    } else if (resultado != 'dismissed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ya está instalada, o tu navegador no lo permite aquí. '
            'Busca "Instalar app" en el menú del navegador.',
          ),
        ),
      );
    }
  }

  void _mostrarInstruccionesIOS() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Instalar EduCampus'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('En iPhone la instalación se hace desde Safari:'),
            SizedBox(height: 12),
            Text('1. Toca el botón Compartir (el cuadro con la flecha hacia arriba).'),
            SizedBox(height: 6),
            Text('2. Baja y selecciona "Agregar a pantalla de inicio".'),
            SizedBox(height: 6),
            Text('3. Confirma. El ícono de EduCampus quedará en tu pantalla de inicio.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2A5C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: guarda tu foto en assets/images/fondo_login.jpg
          Image.asset(
            'assets/images/fondo_login.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F2A5C), Color(0xFF2E5EAA)],
                ),
              ),
            ),
          ),
          // Tinte azul oscuro sobre la foto
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F2A5C).withValues(alpha: 0.72),
                  const Color(0xFF0F2A5C).withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          _contenido(),
        ],
      ),
    );
  }

  Widget _contenido() {
    return Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final ancho = constraints.maxWidth >= 760;
                        if (ancho) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 5, child: _panelImagen(false)),
                                Expanded(flex: 4, child: _panelFormulario()),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: [
                            SizedBox(height: 260, child: _panelImagen(true)),
                            _panelFormulario(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
    );
  }

  Widget _panelImagen(bool compacto) {
    return Container(
      constraints: BoxConstraints(minHeight: compacto ? 0 : 560),
      color: const Color(0xFFF4F3EF),
      padding: EdgeInsets.all(compacto ? 16 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: compacto ? 150 : 340),
              child: Image.asset(
                'assets/images/logo_colmas.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: compacto ? 8 : 24),
          Text(
            'Ingreso a',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compacto ? 13 : 16,
            ),
          ),
          Text(
            'EduCampus',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: compacto ? 24 : 34,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelFormulario() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Iniciar sesión',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const Text('EduCampus · Sistema de Gestión Educativa',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 26),
            LabeledTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              hint: 'usuario@gmail.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu correo';
                }
                if (!_correoRegex.hasMatch(value.trim())) {
                  return 'Correo no válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: !_verPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _verPassword = !_verPassword),
                    icon: Icon(
                        _verPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 16),
                    label: Text(_verPassword ? 'Ocultar' : 'Mostrar',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            if (_errorMensaje != null) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF5C2C0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFC0392B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMensaje!,
                        style: const TextStyle(
                          color: Color(0xFFC0392B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ingresar',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => mostrarRecuperarContrasena(context),
                child: const Text('¿Olvidaste tu contraseña?',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
            if (_mostrarBotonDescargar) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _descargarApp,
                  icon: Image.asset(
                    'assets/images/logo_colmas.jpg',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  label: const Text('Descargar app'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
