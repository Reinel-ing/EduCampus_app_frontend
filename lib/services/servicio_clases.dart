import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/clase_finalizada.dart';
import 'api_config.dart';
import 'utilidad_fechas.dart';

class ClasesService extends ChangeNotifier {
  static final ClasesService _instance = ClasesService._internal();
  factory ClasesService() => _instance;
  ClasesService._internal();

  final List<ClaseFinalizada> _clases = [];
  bool _cargando = false;
  bool _intentoCarga = false;

  List<ClaseFinalizada> get clases {
    final lista = List<ClaseFinalizada>.from(_clases);
    lista.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    return lista;
  }

  List<ClaseFinalizada> get noVistas => clases;
  bool get cargando => _cargando;

  Future<void> cargarDesdeBackendSiHaceFalta() async {
    if (_intentoCarga) return;
    await cargarDesdeBackend();
  }

  Future<void> cargarDesdeBackend() async {
    _intentoCarga = true;
    _cargando = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/clases-finalizadas/');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 45));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;

        _clases
          ..clear()
          ..addAll(datos.map((c) => ClaseFinalizada(
                id: (c['id'] as int).toString(),
                docenteNombre: c['docente_nombre'] as String,
                materia: c['materia'] as String,
                grado: c['grado'] as String,
                observacion: c['observacion'] as String? ?? '',
                fechaHora: parsearFechaHoraUtc(c['fecha_hora'] as String),
              )));
      }
    } catch (_) {
      // Sin conexión al backend: se conserva lo que ya hay en memoria.
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void registrar({
    required String docenteNombre,
    required String materia,
    required String grado,
    String observacion = '',
  }) {
    _clases.add(ClaseFinalizada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      docenteNombre: docenteNombre,
      materia: materia,
      grado: grado,
      observacion: observacion,
    ));
    notifyListeners();
  }
}
