import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/materia.dart';
import '../../models/docente.dart';
import '../../services/academic_service.dart';
import '../../services/servicio_docentes.dart';
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

  @override
  void initState() {
    super.initState();
    if (GradoService().grados.isEmpty) {
      GradoService().cargarDesdeBackend();
    }
    if (TeacherService().teachers.isEmpty) {
      TeacherService().cargarDesdeBackend();
    }
    _service.cargarDesdeBackend();
  }

  void _abrirFormularioMateria() async {
    if (GradoService().grados.isEmpty) {
      await GradoService().cargarDesdeBackend();
    }
    if (TeacherService().teachers.isEmpty) {
      await TeacherService().cargarDesdeBackend();
    }

    if (!mounted) return;

    if (GradoService().grados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes crear al menos un grado.')),
      );
      return;
    }

    if (TeacherService().teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes registrar al menos un docente.')),
      );
      return;
    }

    final nombreCtrl = TextEditingController();
    String grado = GradoService().grados.first;
    Teacher docente = TeacherService().teachers.first;
    bool guardando = false;

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
              DropdownButtonFormField<Teacher>(
                initialValue: docente,
                decoration: const InputDecoration(labelText: 'Docente asignado'),
                items: TeacherService()
                    .teachers
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.nombreCompleto)))
                    .toList(),
                onChanged: (v) => setDialogState(() => docente = v ?? docente),
              ),
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
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.trim().isEmpty) return;
                      setDialogState(() => guardando = true);

                      final error = await _service.agregarMateria(
                        nombre: nombreCtrl.text.trim(),
                        instructorId: int.parse(docente.id),
                        gradoId: GradoService().idPorNombre(grado),
                      );

                      if (!context.mounted) return;

                      if (error != null) {
                        setDialogState(() => guardando = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }

                      Navigator.pop(context);
                    },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFormularioHorario([Materia? materiaInicial]) async {
    final materias = _service.materias;
    if (materias.isEmpty) return;

    Materia materiaSeleccionada = materiaInicial ?? materias.first;
    String dia = diasSemana.first;
    final inicioCtrl = TextEditingController(text: '07:00');
    final finCtrl = TextEditingController(text: '08:00');
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar horario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Materia>(
                  initialValue: materiaSeleccionada,
                  decoration: const InputDecoration(labelText: 'Curso'),
                  items: materias
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('${m.nombre} · ${m.grado}'),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => materiaSeleccionada = v ?? materiaSeleccionada),
                ),
                const SizedBox(height: 12),
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      setDialogState(() => guardando = true);

                      final error = await _service.agregarHorarioEntry(
                        materiaId: materiaSeleccionada.id,
                        dia: dia,
                        horaInicio: inicioCtrl.text.trim(),
                        horaFin: finCtrl.text.trim(),
                      );

                      if (!context.mounted) return;

                      if (error != null) {
                        setDialogState(() => guardando = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }

                      Navigator.pop(context);
                    },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarMateria(Materia m) async {
    final error = await _service.eliminarMateria(m.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: Listenable.merge([_service, GradoService()]),
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
                          child: _service.cargando
                              ? const Center(child: CircularProgressIndicator())
                              : materiasFiltradas.isEmpty
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
                                            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _eliminarMateria(m)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _service.materias.isEmpty ? null : () => _abrirFormularioHorario(),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar horario'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          WeeklyScheduleGrid(entries: horarioFiltrado),
                        ],
                      ),
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
