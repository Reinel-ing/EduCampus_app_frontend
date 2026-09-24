/// El backend guarda las fechas con hora en UTC pero las envía sin indicarlo
/// (sin sufijo "Z"), asi que `DateTime.parse` las interpretaria como si ya
/// fueran la hora local del navegador, adelantando el reloj varias horas.
/// Esta funcion fuerza la interpretacion correcta como UTC y la convierte
/// a la hora local para mostrarla.
final _tieneZonaHoraria = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

DateTime parsearFechaHoraUtc(String iso) {
  final normalizada = _tieneZonaHoraria.hasMatch(iso) ? iso : '${iso}Z';
  return DateTime.parse(normalizada).toLocal();
}
