import 'dart:math';
import '../models/notificacion.dart';
import 'servicio_acudientes.dart';
import 'servicio_docentes.dart';
import 'servicio_notificaciones.dart';

enum ResultadoRecuperacion { solicitudEnviada, correoNoPermitido, correoNoRegistrado }

/// Recuperación de contraseña. Solo se aceptan correos @gmail.com que
/// pertenezcan a una cuenta registrada (docente o acudiente).
///
/// Como aún no hay backend que envíe correos, se genera una contraseña nueva,
/// se asigna a la cuenta y se avisa al administrador con los datos para que
/// se la haga llegar al correo del usuario.
class RecuperacionService {
  static final _gmail = RegExp(r'^[a-z0-9._%+-]+@gmail\.com$');

  static bool esGmail(String correo) => _gmail.hasMatch(correo.trim().toLowerCase());

  static String _nuevaContrasena() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final r = Random.secure();
    final digitos = List.generate(5, (_) => r.nextInt(10)).join();
    return '${letras[r.nextInt(letras.length)]}${letras[r.nextInt(letras.length)]}$digitos';
  }

  static ResultadoRecuperacion solicitar(String correo) {
    final email = correo.trim().toLowerCase();
    if (!esGmail(email)) return ResultadoRecuperacion.correoNoPermitido;

    final nueva = _nuevaContrasena();
    String? nombre;
    String? tipo;

    for (final t in TeacherService().teachers) {
      if (t.correo.trim().toLowerCase() == email) {
        t.contrasena = nueva;
        TeacherService().updateTeacher(t);
        nombre = t.nombreCompleto;
        tipo = 'Docente';
        break;
      }
    }

    if (nombre == null) {
      for (final c in AcudientesService().cuentas) {
        if (c.correo.trim().toLowerCase() == email) {
          c.contrasena = nueva;
          AcudientesService().actualizar(c);
          nombre = c.nombre;
          tipo = 'Acudiente';
          break;
        }
      }
    }

    if (nombre == null) return ResultadoRecuperacion.correoNoRegistrado;

    NotificationService().agregar(
      rol: RolNotificacion.admin,
      titulo: 'Recuperación de contraseña',
      mensaje: '$tipo $nombre olvidó su contraseña.\n'
          'Correo: $email\n'
          'Nueva contraseña temporal: $nueva\n'
          'Envíasela a ese correo.',
    );
    return ResultadoRecuperacion.solicitudEnviada;
  }
}
