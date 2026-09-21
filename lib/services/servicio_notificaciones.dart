import 'package:flutter/foundation.dart';
import '../models/notificacion.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<Notificacion> _notificaciones = [];

  List<Notificacion> get todas => List.unmodifiable(_notificaciones);

  List<Notificacion> paraRol(RolNotificacion rol) {
    final lista = _notificaciones.where((n) => n.rol == rol).toList();
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  int noLeidasParaRol(RolNotificacion rol) {
    return _notificaciones.where((n) => n.rol == rol && !n.leida).length;
  }

  void agregar({
    required RolNotificacion rol,
    required String titulo,
    required String mensaje,
    String? destinatarioId,
  }) {
    _notificaciones.add(Notificacion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      rol: rol,
      destinatarioId: destinatarioId,
      titulo: titulo,
      mensaje: mensaje,
    ));
    notifyListeners();
  }

  void marcarLeida(String id) {
    final n = _notificaciones.firstWhere((n) => n.id == id, orElse: () => throw StateError('no existe'));
    n.leida = true;
    notifyListeners();
  }

  void marcarTodasLeidas(RolNotificacion rol) {
    for (final n in _notificaciones.where((n) => n.rol == rol)) {
      n.leida = true;
    }
    notifyListeners();
  }
}