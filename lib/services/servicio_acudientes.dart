import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/acudiente_cuenta.dart';
import 'api_config.dart';

class AcudientesService extends ChangeNotifier {
  static final AcudientesService _instance = AcudientesService._internal();
  factory AcudientesService() => _instance;
  AcudientesService._internal();

  final List<AcudienteCuenta> _cuentas = [];
  String? _cuentaActualId;
  bool _cargando = false;

  List<AcudienteCuenta> get cuentas => List.unmodifiable(_cuentas);
  bool get cargando => _cargando;

  Future<void> cargarDesdeBackend() async {
    _cargando = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/acudientes/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

        _cuentas
          ..clear()
          ..addAll(datos.map((d) => AcudienteCuenta(
                id: d['id'].toString(),
                nombre: d['nombre'] as String? ?? '',
                correo: d['correo'] as String? ?? '',
                telefono: d['telefono'] as String? ?? '',
                contrasena: '',
              )));
      }
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cuenta activa: la seleccionada al iniciar sesión, o la primera si no hay selección.
  AcudienteCuenta? get cuentaActual {
    if (_cuentaActualId != null) {
      try {
        return _cuentas.firstWhere((c) => c.id == _cuentaActualId);
      } catch (_) {}
    }
    return _cuentas.isNotEmpty ? _cuentas.first : null;
  }

  void seleccionarCuenta(String? id) {
    _cuentaActualId = id;
    notifyListeners();
  }

  String _generarContrasena(String telefono) {
    final digits = telefono.replaceAll(RegExp(r'\D'), '');
    final last5 =
        digits.length >= 5 ? digits.substring(digits.length - 5) : digits;
    return 'AC$last5';
  }

  void agregarExistente(AcudienteCuenta cuenta) {
    _cuentas.add(cuenta);
    notifyListeners();
  }

  AcudienteCuenta registrar({
    required String nombre,
    required String correo,
    required String telefono,
    List<String>? estudianteIds,
  }) {
    final contrasena = _generarContrasena(telefono);
    final cuenta = AcudienteCuenta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      correo: correo,
      telefono: telefono,
      contrasena: contrasena,
      estudianteIds: estudianteIds,
    );
    _cuentas.add(cuenta);
    notifyListeners();
    return cuenta;
  }

  void actualizar(AcudienteCuenta cuenta) {
    final index = _cuentas.indexWhere((c) => c.id == cuenta.id);
    if (index != -1) {
      _cuentas[index] = cuenta;
      notifyListeners();
    }
  }

  void eliminar(String id) {
    if (_cuentaActualId == id) _cuentaActualId = null;
    _cuentas.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}