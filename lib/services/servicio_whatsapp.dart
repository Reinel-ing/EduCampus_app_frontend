import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  WhatsAppService._();

  static String _limpiarTelefono(String telefono) {
    var limpio = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (limpio.length <= 10) {
      limpio = '57$limpio';
    }
    return limpio;
  }

  static Future<bool> enviarMensaje({
    required String telefono,
    required String mensaje,
  }) async {
    if (telefono.trim().isEmpty) return false;
    final numero = _limpiarTelefono(telefono);
    final url = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}');
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> notificarRecogida({
    required String telefono,
    required String nombreEstudiante,
  }) {
    return enviarMensaje(
      telefono: telefono,
      mensaje: 'Hola, le informamos desde COLMAS que ya puede recoger a $nombreEstudiante en la institución. ¡Gracias!',
    );
  }

  static Future<bool> notificarClaseFinalizada({
    required String telefono,
    required String nombreEstudiante,
    required String materia,
  }) {
    return enviarMensaje(
      telefono: telefono,
      mensaje: 'Hola, le informamos desde COLMAS que la clase de $materia de $nombreEstudiante ha finalizado.',
    );
  }
}