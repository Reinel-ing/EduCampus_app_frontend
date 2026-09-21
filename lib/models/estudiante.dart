class Student {
  String id;
  String nombres;
  String apellidos;
  String fechaNacimiento;
  String grado;
  String acudienteNombre;
  String acudienteTelefono;
  String acudienteParentesco;
  String acudienteCorreo;
  Map<String, String> camposPersonalizados;

  Student({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.grado,
    required this.acudienteNombre,
    required this.acudienteTelefono,
    required this.acudienteParentesco,
    this.acudienteCorreo = '',
    Map<String, String>? camposPersonalizados,
  }) : camposPersonalizados = camposPersonalizados ?? {};

  String get nombreCompleto => '$nombres $apellidos';
}