import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'core/theme/tema_app.dart';
import 'core/destino_por_rol.dart';
import 'services/servicio_formularios.dart';
import 'services/servicio_auth.dart';
import 'screens/auth/pantalla_inicio_sesion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // En Flutter Web, el motor reserva el primer toque de la pagina para
  // activar el arbol de semantica (accesibilidad) mediante un elemento
  // invisible a pantalla completa. Eso hace que en iOS Safari el primer
  // toque sobre cualquier campo (por ejemplo el correo del login) se
  // "pierda" y haya que tocar dos veces. Al activar la semantica de una
  // vez al arrancar, ese toque de calentamiento deja de ser necesario.
  SemanticsBinding.instance.ensureSemantics();
  await FormulariosService().cargar();
  runApp(const EduCampusApp());
}

class EduCampusApp extends StatelessWidget {
  const EduCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduCampus - COLMAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _ArranqueApp(),
    );
  }
}

/// Decide qué pantalla mostrar al abrir la app: si hay una sesión guardada
/// y válida, restaura al usuario en su panel; si no, muestra el login.
class _ArranqueApp extends StatefulWidget {
  const _ArranqueApp();

  @override
  State<_ArranqueApp> createState() => _ArranqueAppState();
}

class _ArranqueAppState extends State<_ArranqueApp> {
  @override
  void initState() {
    super.initState();
    _restaurar();
  }

  Future<void> _restaurar() async {
    final sesion = await AuthService().restaurarSesion();

    if (!mounted) return;

    if (sesion != null) {
      final destino = destinoParaRol(sesion.rol, sesion.correo);
      if (destino != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => destino),
        );
        return;
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}