import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/materia.dart';
import '../../models/horario_entry.dart';
import '../../services/academic_service.dart';
import '../../widgets/weekly_schedule_grid.dart';
import '../../services/servicio_grados.dart';
class HorarioAdminScreen extends StatefulWidget {
  const HorarioAdminScreen({super.key});

  @override
  State<HorarioAdminScreen> createState() => _HorarioAdminScreenState();
}

class _HorarioAdminScreenState extends State<HorarioAdminScreen> with SingleTickerProviderStateMixin {
  final _service = AcademicService();
  String? _gradoFiltro;

  void _abrirFormularioMateria() async {
    final nombreCtrl = TextEditingController();
    final docenteCtrl = TextEditingController();
    String grado = GradoService().grados.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva materia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la materia')),
              const SizedBox(height: 12),
              TextField(controller: docenteCtrl, decoration: const InputDecoration(labelText: 'Docente asignado')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: grado,
                decoration: const InputDecoration(labelText: 'Grado'),
                items: GradoService().grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setDialogState(() => grado = v ?? grado),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty || docenteCtrl.text.trim().isEmpty) return;
                _service.addMateria(nombre: nombreCtrl.text.trim(), grado: grado, docenteNombre: docenteCtrl.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFormularioHorario(Materia materia) async {
    String dia = diasSemana.first;
    final inicioCtrl = TextEditingController(text: '07:00');
    final finCtrl = TextEditingController(text: '08:00');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Horario para ${materia.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: dia,
                decoration: const InputDecoration(labelText: 'Día'),
                items: diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setDialogState(() => dia = v ?? dia),
              ),
              const SizedBox(height: 12),
              TextField(controller: inicioCtrl, decoration: const InputDecoration(labelText: 'Hora inicio (HH:MM)')),
              const SizedBox(height: 12),
              TextField(controller: finCtrl, decoration: const InputDecoration(labelText: 'Hora fin (HH:MM)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                _service.addHorarioEntry(materiaId: materia.id, dia: dia, horaInicio: inicioCtrl.text.trim(), horaFin: finCtrl.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final materiasFiltradas = _gradoFiltro == null
              ? _service.materias
              : _service.materias.where((m) => m.grado == _gradoFiltro).toList();

          final horarioFiltrado = _gradoFiltro == null
              ? _service.horario
              : _service.horarioPorGrado(_gradoFiltro!);

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: AppColors.primary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Materias'),
                    Tab(text: 'Horario semanal'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _gradoFiltro,
                                  decoration: const InputDecoration(labelText: 'Filtrar por grado', isDense: true),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Todos los grados')),
                                    ...GradoService().grados.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                                  ],
                                  onChanged: (v) => setState(() => _gradoFiltro = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _abrirFormularioMateria,
                                icon: const Icon(Icons.add),
                                label: const Text('Materia'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: materiasFiltradas.isEmpty
                              ? const Center(child: Text('No hay materias registradas', style: TextStyle(color: AppColors.textSecondary)))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: materiasFiltradas.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final m = materiasFiltradas[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border(left: BorderSide(color: m.color, width: 4)),
                                      ),
                                      child: ListTile(
                                        title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text('${m.grado} · ${m.docenteNombre}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(icon: const Icon(Icons.schedule, color: AppColors.primary), onPressed: () => _abrirFormularioHorario(m)),
                                            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _service.deleteMateria(m.id)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: WeeklyScheduleGrid(entries: horarioFiltrado),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}