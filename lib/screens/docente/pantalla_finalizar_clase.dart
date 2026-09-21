import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/estudiante.dart';
import '../../services/servicio_clases.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_grados.dart';
import '../../services/servicio_whatsapp.dart';
import '../../widgets/campo_texto_etiquetado.dart';

class FinalizarClaseScreen extends StatefulWidget {
  const FinalizarClaseScreen({super.key});

  @override
  State<FinalizarClaseScreen> createState() => _FinalizarClaseScreenState();
}

class _FinalizarClaseScreenState extends State<FinalizarClaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materiaController = TextEditingController();
  final _docenteController = TextEditingController();
  final _observacionController = TextEditingController();

  String _grado = GradoService().grados.first;
  bool _notificarAcudientes = true;
  bool _enviando = false;

  @override
  void dispose() {
    _materiaController.dispose();
    _docenteController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _finalizar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    ClasesService().registrar(
      docenteNombre: _docenteController.text.trim(),
      materia: _materiaController.text.trim(),
      grado: _grado,
      observacion: _observacionController.text.trim(),
    );

    if (_notificarAcudientes) {
      final estudiantes = StudentService().students.where((Student s) => s.grado == _grado).toList();
      for (final s in estudiantes) {
        if (s.acudienteTelefono.isNotEmpty) {
          await WhatsAppService.notificarRecogida(
            telefono: s.acudienteTelefono,
            nombreEstudiante: s.nombreCompleto,
          );
        }
      }
    }

    setState(() => _enviando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clase finalizada y registrada')),
      );
      _materiaController.clear();
      _observacionController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school_rounded, color: AppColors.primary, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finalizar clase',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        SizedBox(height: 4),
                        Text(
                          'Registra el fin de clase y notifica a los acudientes.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            LabeledTextField(
              controller: _docenteController,
              label: 'Tu nombre',
              hint: 'Nombre del docente',
              icon: Icons.badge_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              controller: _materiaController,
              label: 'Materia',
              hint: 'Ej. Matemáticas',
              icon: Icons.menu_book_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            const Text(
              'GRADO',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _grado,
                  isExpanded: true,
                  items: GradoService().grados
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _grado = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            LabeledTextField(
              controller: _observacionController,
              label: 'Observación (opcional)',
              hint: 'Ej. Tarea: resolver ejercicios 1-5',
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E7EC)),
              ),
              child: SwitchListTile(
                value: _notificarAcudientes,
                onChanged: (v) => setState(() => _notificarAcudientes = v),
                title: const Text('Notificar acudientes por WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Se enviará mensaje de recogida a cada acudiente del grado'),
                activeColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _finalizar,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_enviando ? 'Enviando...' : 'Finalizar clase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}