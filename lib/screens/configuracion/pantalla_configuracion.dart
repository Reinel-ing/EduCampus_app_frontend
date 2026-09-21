import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/servicio_configuracion.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _anioController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;

  @override
  void initState() {
    super.initState();
    final config = ConfiguracionService();
    _nombreController = TextEditingController(text: config.nombreInstitucion);
    _anioController = TextEditingController(text: config.anioEscolar);
    _correoController = TextEditingController(text: config.correoContacto);
    _telefonoController = TextEditingController(text: config.telefonoContacto);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _anioController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    ConfiguracionService().actualizar(
      nombreInstitucion: _nombreController.text.trim(),
      anioEscolar: _anioController.text.trim(),
      correoContacto: _correoController.text.trim(),
      telefonoContacto: _telefonoController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  Widget _tarjeta({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required List<Widget> campos,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEFEFF3)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final dosColumnas = constraints.maxWidth >= 560;
              if (!dosColumnas) {
                return Column(
                  children: [
                    for (int i = 0; i < campos.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      campos[i],
                    ],
                  ],
                );
              }
              final ancho = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final c in campos) SizedBox(width: ancho, child: c),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? requerido(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración general',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 22),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Administra la información de la institución y sus datos de contacto.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                ),
                const SizedBox(height: 20),
                _tarjeta(
                  icon: Icons.account_balance_rounded,
                  titulo: 'Datos de la institución',
                  subtitulo: 'Nombre y periodo académico vigente',
                  campos: [
                    LabeledTextField(
                      controller: _nombreController,
                      label: 'Nombre de la institución',
                      hint: 'Nombre del colegio',
                      icon: Icons.school_rounded,
                      validator: requerido,
                    ),
                    LabeledTextField(
                      controller: _anioController,
                      label: 'Año escolar',
                      hint: 'Ej: 2026',
                      icon: Icons.calendar_month_rounded,
                      validator: requerido,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _tarjeta(
                  icon: Icons.contact_mail_rounded,
                  titulo: 'Información de contacto',
                  subtitulo: 'Cómo pueden comunicarse contigo docentes y acudientes',
                  campos: [
                    LabeledTextField(
                      controller: _correoController,
                      label: 'Correo de contacto',
                      hint: 'correo@institucion.edu.co',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    LabeledTextField(
                      controller: _telefonoController,
                      label: 'Teléfono de contacto',
                      hint: 'Número de contacto',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Guardar cambios'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}