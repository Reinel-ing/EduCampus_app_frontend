import 'package:flutter/material.dart';

class Materia {
  final String id;
  String nombre;
  String grado;
  String docenteNombre;
  int? instructorId;
  Color color;

  Materia({
    required this.id,
    required this.nombre,
    required this.grado,
    required this.docenteNombre,
    this.instructorId,
    required this.color,
  });
}