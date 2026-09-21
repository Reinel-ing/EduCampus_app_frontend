import 'estudiante.dart';

/// De dónde toma su valor un campo del formulario cuando se elige un estudiante.
enum OrigenDato {
  manual,
  id,
  nombres,
  apellidos,
  nombreCompleto,
  fechaNacimiento,
  grado,
  acudienteNombre,
  acudienteTelefono,
  acudienteParentesco,
  acudienteCorreo,
  personalizado,
}

extension OrigenDatoInfo on OrigenDato {
  String get etiqueta {
    switch (this) {
      case OrigenDato.manual:
        return 'Escribir manualmente';
      case OrigenDato.id:
        return 'Identificación del estudiante';
      case OrigenDato.nombres:
        return 'Nombres';
      case OrigenDato.apellidos:
        return 'Apellidos';
      case OrigenDato.nombreCompleto:
        return 'Nombre completo';
      case OrigenDato.fechaNacimiento:
        return 'Fecha de nacimiento';
      case OrigenDato.grado:
        return 'Grado';
      case OrigenDato.acudienteNombre:
        return 'Nombre del acudiente';
      case OrigenDato.acudienteTelefono:
        return 'Teléfono del acudiente';
      case OrigenDato.acudienteParentesco:
        return 'Parentesco del acudiente';
      case OrigenDato.acudienteCorreo:
        return 'Correo del acudiente';
      case OrigenDato.personalizado:
        return 'Campo personalizado del estudiante';
    }
  }

  /// Valor del estudiante para este origen. [campoPersonalizadoId] se usa
  /// solo con [OrigenDato.personalizado].
  String valorDe(Student s, {String? campoPersonalizadoId}) {
    switch (this) {
      case OrigenDato.manual:
        return '';
      case OrigenDato.id:
        return s.id;
      case OrigenDato.nombres:
        return s.nombres;
      case OrigenDato.apellidos:
        return s.apellidos;
      case OrigenDato.nombreCompleto:
        return s.nombreCompleto;
      case OrigenDato.fechaNacimiento:
        return s.fechaNacimiento;
      case OrigenDato.grado:
        return s.grado;
      case OrigenDato.acudienteNombre:
        return s.acudienteNombre;
      case OrigenDato.acudienteTelefono:
        return s.acudienteTelefono;
      case OrigenDato.acudienteParentesco:
        return s.acudienteParentesco;
      case OrigenDato.acudienteCorreo:
        return s.acudienteCorreo;
      case OrigenDato.personalizado:
        return s.camposPersonalizados[campoPersonalizadoId] ?? '';
    }
  }
}

class CampoFormulario {
  final String id;
  String etiqueta;
  OrigenDato origen;
  String? campoPersonalizadoId;

  CampoFormulario({
    required this.id,
    required this.etiqueta,
    this.origen = OrigenDato.manual,
    this.campoPersonalizadoId,
  });

  String valorPara(Student s) =>
      origen.valorDe(s, campoPersonalizadoId: campoPersonalizadoId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'etiqueta': etiqueta,
        'origen': origen.name,
        'campoPersonalizadoId': campoPersonalizadoId,
      };

  factory CampoFormulario.fromJson(Map<String, dynamic> json) =>
      CampoFormulario(
        id: json['id'] as String,
        etiqueta: json['etiqueta'] as String? ?? '',
        origen: OrigenDato.values.firstWhere(
          (o) => o.name == json['origen'],
          orElse: () => OrigenDato.manual,
        ),
        campoPersonalizadoId: json['campoPersonalizadoId'] as String?,
      );
}

class PlantillaFormulario {
  final String id;
  String nombre;
  String descripcion;
  final List<CampoFormulario> campos;

  PlantillaFormulario({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    List<CampoFormulario>? campos,
  }) : campos = campos ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'campos': [for (final c in campos) c.toJson()],
      };

  factory PlantillaFormulario.fromJson(Map<String, dynamic> json) =>
      PlantillaFormulario(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        campos: [
          for (final c in (json['campos'] as List? ?? []))
            CampoFormulario.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
      );
}
