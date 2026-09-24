import 'package:flutter/material.dart';
import '../../core/theme/colores_app.dart';
import '../../models/acudiente_cuenta.dart';
import '../../models/notificacion.dart';
import '../../services/servicio_acudientes.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_notificaciones.dart';
import '../../services/servicio_notificaciones_backend.dart';

class NotificacionesScreen extends StatefulWidget {
  final RolNotificacion rol;
  const NotificacionesScreen({super.key, required this.rol});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<NotificacionBackend> _notificacionesReales = [];
  bool _cargando = false;

  bool get _esRolConectado =>
      widget.rol == RolNotificacion.acudiente || widget.rol == RolNotificacion.docente;

  @override
  void initState() {
    super.initState();
    if (_esRolConectado) {
      _cargarNotificacionesReales();
    }
  }

  Future<void> _cargarNotificacionesReales() async {
    setState(() => _cargando = true);

    if (widget.rol == RolNotificacion.docente) {
      final profesorId = AuthService().sesionActual?.usuarioId;

      if (profesorId == null) {
        if (mounted) setState(() => _cargando = false);
        return;
      }

      final notificaciones = await NotificacionesBackendService().obtenerParaDocente(profesorId);

      if (!mounted) return;

      setState(() {
        _notificacionesReales = notificaciones;
        _cargando = false;
      });
      return;
    }

    if (AcudientesService().cuentas.isEmpty) {
      await AcudientesService().cargarDesdeBackend();
    }

    final correo = AuthService().sesionActual?.correo;
    AcudienteCuenta? cuenta;
    for (final c in AcudientesService().cuentas) {
      if (c.correo.trim().toLowerCase() == correo) {
        cuenta = c;
        break;
      }
    }
    cuenta ??= AcudientesService().cuentaActual;

    if (cuenta == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    final acudienteId = int.tryParse(cuenta.id);
    if (acudienteId == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    final notificaciones =
        await NotificacionesBackendService().obtenerParaAcudiente(acudienteId);

    if (!mounted) return;

    setState(() {
      _notificacionesReales = notificaciones;
      _cargando = false;
    });
  }

  IconData _iconoPara(String tipo, String titulo) {
    if (tipo == 'recogida' || titulo.toLowerCase().contains('recoger')) {
      return Icons.directions_walk_rounded;
    }
    if (tipo == 'entrega') return Icons.assignment_turned_in_rounded;
    if (tipo == 'alerta') return Icons.warning_amber_rounded;
    return Icons.campaign_rounded;
  }

  Future<void> _marcarLeidaReal(NotificacionBackend n) async {
    if (n.leida) return;
    await NotificacionesBackendService().marcarLeida(n.id);
    _cargarNotificacionesReales();
  }

  @override
  Widget build(BuildContext context) {
    if (_esRolConectado) {
      return _construirListaReal();
    }
    return _construirListaLocal();
  }

  Widget _construirListaReal() {
    if (_cargando && _notificacionesReales.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notificacionesReales.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarNotificacionesReales,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text('No hay notificaciones por ahora',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificacionesReales,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notificacionesReales.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final n = _notificacionesReales[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: n.leida ? const Color(0xFFE7E7EC) : AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(_iconoPara(n.tipo, n.titulo), color: AppColors.primary),
              ),
              title: Text(n.titulo,
                  style: TextStyle(fontWeight: n.leida ? FontWeight.w500 : FontWeight.bold)),
              subtitle: Text(n.mensaje),
              trailing: Text(
                '${n.fecha.hour.toString().padLeft(2, '0')}:${n.fecha.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              onTap: () => _marcarLeidaReal(n),
            ),
          );
        },
      ),
    );
  }

  Widget _construirListaLocal() {
    final service = NotificationService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final lista = service.paraRol(widget.rol);

        if (lista.isEmpty) {
          return const Center(
            child: Text('No hay notificaciones por ahora', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final n = lista[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: n.leida ? const Color(0xFFE7E7EC) : AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(_iconoPara('', n.titulo), color: AppColors.primary),
                ),
                title: Text(n.titulo, style: TextStyle(fontWeight: n.leida ? FontWeight.w500 : FontWeight.bold)),
                subtitle: Text(n.mensaje),
                trailing: Text(
                  '${n.fecha.hour.toString().padLeft(2, '0')}:${n.fecha.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                onTap: () => service.marcarLeida(n.id),
              ),
            );
          },
        );
      },
    );
  }
}
