import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/actividad.dart';
import '../models/estudiante.dart';
import 'servicio_estudiantes.dart';

class ActividadesService extends ChangeNotifier {
  static final ActividadesService _instance = ActividadesService._internal();
  factory ActividadesService() => _instance;
  ActividadesService._internal();

  final List<Actividad> _actividades = [];
  final List<Entrega> _entregas = [];

  List<Actividad> get actividades {
    final lista = List<Actividad>.from(_actividades);
    lista.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    return List.unmodifiable(lista);
  }

  Actividad agregarActividad({
    required String materia,
    required String grado,
    required String titulo,
    required String descripcion,
    required DateTime fechaEntrega,
    String archivoNombre = '',
    Uint8List? archivoBytes,
  }) {
    final actividad = Actividad(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      materia: materia,
      grado: grado,
      titulo: titulo,
      descripcion: descripcion,
      fechaEntrega: fechaEntrega,
      archivoNombre: archivoNombre,
      archivoBytes: archivoBytes,
    );
    _actividades.add(actividad);

    final estudiantesDelGrado =
        StudentService().students.where((Student s) => s.grado == grado);
    for (final estudiante in estudiantesDelGrado) {
      _entregas.add(Entrega(
        id: '${actividad.id}_${estudiante.id}',
        actividadId: actividad.id,
        estudianteId: estudiante.id,
      ));
    }

    notifyListeners();
    return actividad;
  }

  void eliminarActividad(String id) {
    _actividades.removeWhere((a) => a.id == id);
    _entregas.removeWhere((e) => e.actividadId == id);
    notifyListeners();
  }

  List<Entrega> entregasPorActividad(String actividadId) =>
      _entregas.where((e) => e.actividadId == actividadId).toList();

  List<Entrega> entregasPorEstudiante(String estudianteId) =>
      _entregas.where((e) => e.estudianteId == estudianteId).toList();

  Entrega? entregaDe(String actividadId, String estudianteId) {
    final found = _entregas.where(
      (e) => e.actividadId == actividadId && e.estudianteId == estudianteId,
    );
    return found.isEmpty ? null : found.first;
  }

  int entregadasPorActividad(String actividadId) => _entregas
      .where((e) =>
          e.actividadId == actividadId && e.estado != EstadoEntrega.pendiente)
      .length;

  void actualizarEstadoEntrega(
    String entregaId,
    EstadoEntrega estado, {
    String? retroalimentacion,
  }) {
    final entrega = _entregas.firstWhere((e) => e.id == entregaId);
    entrega.estado = estado;
    if (retroalimentacion != null) entrega.retroalimentacion = retroalimentacion;
    notifyListeners();
  }

  void subirEntregaAcudiente({
    required String entregaId,
    required String archivoUrl,
    String comentario = '',
  }) {
    final entrega = _entregas.firstWhere((e) => e.id == entregaId);
    entrega.archivoUrl = archivoUrl;
    entrega.comentarioAcudiente = comentario;
    entrega.estado = EstadoEntrega.entregado;
    notifyListeners();
  }

  void actualizarEntregaConArchivo(
    String entregaId, {
    required String archivoNombre,
    required Uint8List archivoBytes,
  }) {
    final entrega = _entregas.firstWhere((e) => e.id == entregaId);
    entrega.archivoNombre = archivoNombre;
    entrega.archivoBytes = archivoBytes;
    entrega.estado = EstadoEntrega.entregado;
    notifyListeners();
  }
}