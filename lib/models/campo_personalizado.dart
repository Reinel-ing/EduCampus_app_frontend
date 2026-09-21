enum TipoCampo { texto, numero, fecha, seleccion }

class CustomField {
  final String id;
  final String label;
  final TipoCampo tipo;
  final List<String> opciones;

  CustomField({
    required this.id,
    required this.label,
    this.tipo = TipoCampo.texto,
    List<String>? opciones,
  }) : opciones = opciones ?? [];
}