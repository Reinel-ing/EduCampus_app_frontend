import 'package:flutter/material.dart';
import '../core/theme/colores_app.dart';

enum TipoSituacion { positiva, negativa, neutral }

extension TipoSituacionEstilo on TipoSituacion {
  String get etiqueta {
    switch (this) {
      case TipoSituacion.positiva:
        return 'Positiva';
      case TipoSituacion.negativa:
        return 'Negativa';
      case TipoSituacion.neutral:
        return 'Neutral / Informativa';
    }
  }

  Color get color {
    switch (this) {
      case TipoSituacion.positiva:
        return AppColors.success;
      case TipoSituacion.negativa:
        return AppColors.danger;
      case TipoSituacion.neutral:
        return AppColors.textSecondary;
    }
  }

  IconData get icono {
    switch (this) {
      case TipoSituacion.positiva:
        return Icons.thumb_up_rounded;
      case TipoSituacion.negativa:
        return Icons.report_problem_rounded;
      case TipoSituacion.neutral:
        return Icons.info_rounded;
    }
  }
}

class SituacionConvivencia {
  final String id;
  final String estudianteId;
  TipoSituacion tipo;
  String titulo;
  String descripcion;
  DateTime fecha;
  bool seguimientoRealizado;
  String notaSeguimiento;

  SituacionConvivencia({
    required this.id,
    required this.estudianteId,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    DateTime? fecha,
    this.seguimientoRealizado = false,
    this.notaSeguimiento = '',
  }) : fecha = fecha ?? DateTime.now();
}