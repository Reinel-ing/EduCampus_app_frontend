import 'package:flutter/material.dart';
import 'core/theme/tema_app.dart';
import 'services/servicio_formularios.dart';
import 'screens/auth/pantalla_inicio_sesion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const LoginScreen(),
    );
  }
}