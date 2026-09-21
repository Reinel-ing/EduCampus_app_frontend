class AcudienteCuenta {
  final String id;
  String nombre, correo, telefono, contrasena;
  List<String> estudianteIds;

  AcudienteCuenta({
    required this.id, required this.nombre, required this.correo,
    required this.telefono, required this.contrasena, List<String>? estudianteIds,
  }) : estudianteIds = estudianteIds ?? [];
}