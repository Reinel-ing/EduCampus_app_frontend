import 'package:flutter/material.dart';
import '../screens/admin/panel_admin.dart';
import '../screens/docente/panel_docente.dart';
import '../screens/acudiente/panel_acudiente.dart';
import '../services/servicio_acudientes.dart';

/// Construye la pantalla destino según el rol. Devuelve null si el rol
/// todavía no tiene una pantalla propia en esta app.
Widget? destinoParaRol(String rol, String correo) {
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
