import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/servicio_recuperacion.dart';
import '../../widgets/campo_texto_etiquetado.dart';

Future<void> mostrarRecuperarContrasena(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _RecuperarContrasenaDialog(),
  );
}

class _RecuperarContrasenaDialog extends StatefulWidget {
  const _RecuperarContrasenaDialog();

  @override
  State<_RecuperarContrasenaDialog> createState() =>
      _RecuperarContrasenaDialogState();
}

class _RecuperarContrasenaDialogState
    extends State<_RecuperarContrasenaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  String? _errorServidor;
  bool _enviado = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  void _enviar() {
    setState(() => _errorServidor = null);
    if (!_formKey.currentState!.validate()) return;

    final resultado = RecuperacionService.solicitar(_correo.text);
    setState(() {
      switch (resultado) {
        case ResultadoRecuperacion.solicitudEnviada:
          _enviado = true;
          break;
        case ResultadoRecuperacion.correoNoPermitido:
          _errorServidor = 'Solo se permiten correos @gmail.com';
          break;
        case ResultadoRecuperacion.correoNoRegistrado:
          _errorServidor = 'Ese correo no está registrado en la plataforma';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _enviado ? _confirmacion(context) : _formulario(context),
        ),
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Recuperar contraseña',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Escribe tu correo Gmail registrado. Avisaremos al administrador para que te envíe una contraseña nueva.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          LabeledTextField(
            controller: _correo,
            label: 'Correo Gmail',
            hint: 'usuario@gmail.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!RecuperacionService.esGmail(v)) {
                return 'Solo se permiten correos @gmail.com';
              }
              return null;
            },
          ),
          if (_errorServidor != null) ...[
            const SizedBox(height: 10),
            Text(_errorServidor!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _enviar,
                child: const Text('Solicitar nueva contraseña'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _confirmacion(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_rounded,
            size: 48, color: AppColors.success),
        const SizedBox(height: 12),
        const Text('Solicitud enviada',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        Text(
          'El administrador recibió tu solicitud y te hará llegar la nueva contraseña a ${_correo.text.trim()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ),
      ],
    );
  }
}
