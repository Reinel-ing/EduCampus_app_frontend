import 'package:flutter/material.dart';
import '../models/materia.dart';
import '../models/horario_entry.dart';

export '../models/horario_entry.dart';

const List<String> gradosDisponiblesAcademico = [
  'Prejardín',
  'Jardín',
  'Transición',
  'Primero',
  'Segundo',
  'Tercero',
  'Cuarto',
  'Quinto',
];

class AcademicService extends ChangeNotifier {
  static final AcademicService _instance = AcademicService._internal();
  factory AcademicService() => _instance;
  AcademicService._internal();

  final List<Materia> _materias = [];
  final List<HorarioEntry> _horario = [];

  static const List<Color> _paletaColores = [
    Color(0xFF2E5EAA),
    Color(0xFFF5A623),
    Color(0xFF4CAF50),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
  ];

  List<Materia> get materias => List.unmodifiable(_materias);
  List<HorarioEntry> get horario => List.unmodifiable(_horario);

  Materia? materiaById(String id) {
    for (final m in _materias) {
      if (m.id == id) return m;
    }
    return null;
  }

  void addMateria({
    required String nombre,
    required String grado,
    required String docenteNombre,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final color = _paletaColores[_materias.length % _paletaColores.length];
    _materias.add(Materia(
      id: id,
      nombre: nombre,
      grado: grado,
      docenteNombre: docenteNombre,
      color: color,
    ));
    notifyListeners();
  }

  void deleteMateria(String id) {
    _materias.removeWhere((m) => m.id == id);
    _horario.removeWhere((h) => h.materiaId == id);
    notifyListeners();
  }

  void addHorarioEntry({
    required String materiaId,
    required String dia,
    required String horaInicio,
    required String horaFin,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _horario.add(HorarioEntry(
      id: id,
      materiaId: materiaId,
      dia: dia,
      horaInicio: horaInicio,
      horaFin: horaFin,
    ));
    notifyListeners();
  }

  void deleteHorarioEntry(String id) {
    _horario.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  List<HorarioEntry> horarioPorGrado(String grado) {
    final idsMaterias = _materias.where((m) => m.grado == grado).map((m) => m.id).toSet();
    return _horario.where((h) => idsMaterias.contains(h.materiaId)).toList();
  }

  List<HorarioEntry> horarioPorDocente(String docenteNombre) {
    final nombre = docenteNombre.toLowerCase().trim();
    final idsMaterias = _materias
        .where((m) => m.docenteNombre.toLowerCase().trim() == nombre)
        .map((m) => m.id)
        .toSet();
    return _horario.where((h) => idsMaterias.contains(h.materiaId)).toList();
  }

  List<Materia> materiasPorDocente(String docenteNombre) {
    final nombre = docenteNombre.toLowerCase().trim();
    return _materias.where((m) => m.docenteNombre.toLowerCase().trim() == nombre).toList();
  }
}