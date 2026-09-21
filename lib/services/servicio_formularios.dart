import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/formulario.dart';

class FormulariosService extends ChangeNotifier {
  static final FormulariosService _instance = FormulariosService._internal();
  factory FormulariosService() => _instance;
  FormulariosService._internal();

  static const _clave = 'plantillas_formularios';

  final List<PlantillaFormulario> _plantillas = [];

  List<PlantillaFormulario> get plantillas => List.unmodifiable(_plantillas);

  static String nuevoId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Carga las plantillas guardadas. Se llama una vez al iniciar la app.
  Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final crudo = prefs.getString(_clave);
      if (crudo == null) return;
      final lista = jsonDecode(crudo) as List;
      _plantillas
        ..clear()
        ..addAll(lista.map((p) =>
            PlantillaFormulario.fromJson(Map<String, dynamic>.from(p as Map))));
      notifyListeners();
    } catch (e) {
      debugPrint('No se pudieron cargar los formularios: $e');
    }
  }

  Future<void> _persistir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clave,
        jsonEncode([for (final p in _plantillas) p.toJson()]),
      );
    } catch (e) {
      debugPrint('No se pudieron guardar los formularios: $e');
    }
  }

  void guardar(PlantillaFormulario plantilla) {
    final index = _plantillas.indexWhere((p) => p.id == plantilla.id);
    if (index == -1) {
      _plantillas.add(plantilla);
    } else {
      _plantillas[index] = plantilla;
    }
    notifyListeners();
    _persistir();
  }

  void eliminar(String id) {
    _plantillas.removeWhere((p) => p.id == id);
    notifyListeners();
    _persistir();
  }
}
