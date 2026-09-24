import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/colores_app.dart';

Future<void> _copiar(BuildContext context, String contrasena) async {
  await Clipboard.setData(ClipboardData(text: contrasena));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Contraseña copiada'), duration: Duration(seconds: 2)),
  );
}

/// Caja destacada con la contraseña seleccionable y un botón para copiarla,
/// usada en los diálogos de creación/restablecimiento de cuentas.
class ContrasenaCopiable extends StatelessWidget {
  final String contrasena;
  const ContrasenaCopiable({super.key, required this.contrasena});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              contrasena,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Copiar contraseña',
            icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
            onPressed: () => _copiar(context, contrasena),
          ),
        ],
      ),
    );
  }
}

/// Línea compacta para mostrar la contraseña dentro de una fila de lista,
/// con ícono para copiarla. No se muestra nada si la contraseña está vacía
/// (cuenta creada/editada en otra sesión: el backend nunca la expone).
class ContrasenaEnLista extends StatelessWidget {
  final String contrasena;
  const ContrasenaEnLista({super.key, required this.contrasena});

  @override
  Widget build(BuildContext context) {
    if (contrasena.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.key_rounded, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          SelectableText(
            contrasena,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _copiar(context, contrasena),
            child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
