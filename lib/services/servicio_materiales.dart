import 'package:flutter/foundation.dart';
import '../models/material_didactico.dart';

class MaterialService extends ChangeNotifier {
  static final MaterialService _instance = MaterialService._internal();
  factory MaterialService() => _instance;
  MaterialService._internal();

  final List<MaterialDidactico> _materiales = [];

  List<MaterialDidactico> get materiales {
    final lista = List<MaterialDidactico>.from(_materiales);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return List.unmodifiable(lista);
  }

  void agregar(MaterialDidactico material) {
    _materiales.add(material);
    notifyListeners();
  }

  void eliminar(String id) {
    _materiales.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}