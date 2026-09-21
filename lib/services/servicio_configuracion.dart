import 'package:flutter/foundation.dart';

class ConfiguracionService extends ChangeNotifier {
  static final ConfiguracionService _instance = ConfiguracionService._internal();
  factory ConfiguracionService() => _instance;
  ConfiguracionService._internal();

  String nombreInstitucion = 'Colegio Manantial de Sabiduría';
  String anioEscolar = '2026';
  String correoContacto = '';
  String telefonoContacto = '';

  void actualizar({
    required String nombreInstitucion,
    required String anioEscolar,
    required String correoContacto,
    required String telefonoContacto,
  }) {
    this.nombreInstitucion = nombreInstitucion;
    this.anioEscolar = anioEscolar;
    this.correoContacto = correoContacto;
    this.telefonoContacto = telefonoContacto;
    notifyListeners();
  }
}