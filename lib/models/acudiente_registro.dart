class AcudienteRegistrado {
  String id;
  String nombres;
  String apellidos;
  String documento;
  String telefono;
  String correo;
  String password;
  String parentesco;
  List<String> estudiantesIds;

  AcudienteRegistrado({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.documento,
    required this.telefono,
    required this.correo,
    required this.password,
    this.parentesco = '',
    List<String>? estudiantesIds,
  }) : estudiantesIds = estudiantesIds ?? [];

  String get nombreCompleto => '$nombres $apellidos';
}