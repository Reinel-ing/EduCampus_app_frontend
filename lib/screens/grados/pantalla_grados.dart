import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../services/servicio_grados.dart';

class GradosScreen extends StatefulWidget {
  const GradosScreen({super.key});

  @override
  State<GradosScreen> createState() => _GradosScreenState();
}

class _GradosScreenState extends State<GradosScreen> {
  @override
  void initState() {
    super.initState();
    GradoService().cargarDesdeBackend();
  }

  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _abrirFormulario(BuildContext context, {String? gradoExistente}) async {
    final controller = TextEditingController(text: gradoExistente ?? '');
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gradoExistente != null ? 'Editar grado' : 'Nuevo grado'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej: Sexto'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado != null && resultado.isNotEmpty) {
      final error = gradoExistente != null
          ? await GradoService().editar(gradoExistente, resultado)
          : await GradoService().agregar(resultado);

      if (error != null && context.mounted) {
        _mostrarError(context, error);
      }
    }
  }

  Future<void> _confirmarEliminar(BuildContext context, String grado) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grado'),
        content: Text(
          '¿Eliminar "$grado"? Los estudiantes o docentes ya asignados a este grado conservarán el nombre, pero no podrás volver a seleccionarlo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      final error = await GradoService().eliminar(grado);
      if (error != null && context.mounted) {
        _mostrarError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = GradoService();

    return Stack(
      children: [
        ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final grados = service.grados;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: grados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final g = grados[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7EC)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1A2E5EAA),
                      child: Icon(Icons.class_rounded, color: AppColors.primary),
                    ),
                    title: Text(g, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(context, gradoExistente: g),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(context, g),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _abrirFormulario(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo grado'),
          ),
        ),
      ],
    );
  }
}