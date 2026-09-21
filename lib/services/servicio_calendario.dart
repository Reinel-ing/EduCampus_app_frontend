import 'package:flutter/foundation.dart';
import '../models/evento_calendario.dart';

class CalendarioService extends ChangeNotifier {
  static final CalendarioService _instance = CalendarioService._internal();
  factory CalendarioService() => _instance;
  CalendarioService._internal();

  final List<EventoCalendario> _eventos = [];

  List<EventoCalendario> get eventos {
    final lista = List<EventoCalendario>.from(_eventos);
    lista.sort((a, b) => a.fecha.compareTo(b.fecha));
    return List.unmodifiable(lista);
  }

  void agregar(EventoCalendario evento) {
    _eventos.add(evento);
    notifyListeners();
  }

  void eliminar(String id) {
    _eventos.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}