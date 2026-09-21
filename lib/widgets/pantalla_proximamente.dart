import 'package:flutter/material.dart';
import '../core/theme/colores_app.dart';

class ComingSoonScreen extends StatelessWidget {
  final String moduleName;

  const ComingSoonScreen({super.key, required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('$moduleName — en construcción', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}