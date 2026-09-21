import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/formulario.dart';
import '../../services/servicio_estudiantes.dart';
import '../../services/servicio_formularios.dart';
import 'pantalla_editor_formulario.dart';
import 'pantalla_llenar_formulario.dart';

class FormulariosScreen extends StatelessWidget {
  const FormulariosScreen({super.key});

  void _abrirEditor(BuildContext context, [PlantillaFormulario? plantilla]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorFormularioScreen(plantilla: plantilla),
      ),
    );
  }

  void _abrirLlenado(BuildContext context, PlantillaFormulario plantilla) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LlenarFormularioScreen(plantilla: plantilla),
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, PlantillaFormulario plantilla) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar formulario'),
        content: Text('¿Eliminar "${plantilla.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) FormulariosService().eliminar(plantilla.id);
  }

  @override
  Widget build(BuildContext context) {
    final service = FormulariosService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final plantillas = service.plantillas;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Formularios',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: AppColors.textPrimary)),
                            SizedBox(height: 4),
                            Text(
                              'Crea los formularios con los campos que necesitas. Al buscar un estudiante por nombre, se llenan solos.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _abrirEditor(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nuevo formulario'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (plantillas.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7E7EC)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.dynamic_form_rounded,
                              size: 44, color: AppColors.textSecondary),
                          SizedBox(height: 10),
                          Text('Aún no has creado formularios',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          SizedBox(height: 4),
                          Text(
                            'Pulsa "Nuevo formulario" para definir qué información quieres pedir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final p in plantillas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TarjetaPlantilla(
                          plantilla: p,
                          onLlenar: () => _abrirLlenado(context, p),
                          onEditar: () => _abrirEditor(context, p),
                          onEliminar: () => _confirmarEliminar(context, p),
                        ),
                      ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: StudentService(),
                    builder: (context, _) => Text(
                      '${StudentService().students.length} estudiante(s) disponibles para autocompletar.',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaPlantilla extends StatelessWidget {
  final PlantillaFormulario plantilla;
  final VoidCallback onLlenar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaPlantilla({
    required this.plantilla,
    required this.onLlenar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plantilla.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  plantilla.descripcion.isEmpty
                      ? '${plantilla.campos.length} campo(s)'
                      : '${plantilla.campos.length} campo(s) · ${plantilla.descripcion}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: plantilla.campos.isEmpty ? null : onLlenar,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Llenar'),
          ),
          IconButton(
            tooltip: 'Editar campos',
            onPressed: onEditar,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
