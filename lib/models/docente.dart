class Teacher {
  String id, nombres, apellidos, documento, especialidad, telefono, correo;
  String contrasena;
  List<String> gradosAsignados;

  Teacher({
    required this.id, required this.nombres, required this.apellidos,
    required this.documento, required this.especialidad,
    required this.telefono, required this.correo,
    this.contrasena = '', List<String>? gradosAsignados,
  }) : gradosAsignados = gradosAsignados ?? [];

  String get nombreCompleto => '$nombres $apellidos';
}