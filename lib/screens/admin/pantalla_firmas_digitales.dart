// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/colores_app.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_firmas.dart';

class FirmasDigitalesScreen extends StatefulWidget {
  const FirmasDigitalesScreen({super.key});

  @override
  State<FirmasDigitalesScreen> createState() => _FirmasDigitalesScreenState();
}

class _FirmasDigitalesScreenState extends State<FirmasDigitalesScreen> {
  bool _cargando = true;
  String? _error;
  FirmasListado? _listado;
  int? _subiendoId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final listado = await FirmasService().listar();
      if (!mounted) return;
      setState(() {
        _listado = listado;
        _cargando = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible conectar con el servidor.';
        _cargando = false;
      });
    }
  }

  void _elegirImagen({required bool esAdmin, required int id}) {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();

    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) async {
        final result = reader.result;
        if (result is! List<int>) return;

        final bytes = Uint8List.fromList(result);

        setState(() => _subiendoId = id);

        final error = esAdmin
            ? await FirmasService().subirFirmaAdmin(id, bytes)
            : await FirmasService().subirFirmaDocente(id, bytes);

        if (!mounted) return;

        setState(() => _subiendoId = null);

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firma guardada correctamente')),
        );
        _cargar();
      });
    });
  }

  Widget _tarjetaFirma({
    required String nombre,
    required String etiqueta,
    required bool tieneFirma,
    required bool esAdmin,
    required int id,
  }) {
    final subiendo = _subiendoId == id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (tieneFirma ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.draw_rounded,
              color: tieneFirma ? AppColors.success : AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  tieneFirma ? 'Con firma registrada' : 'Sin firma registrada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tieneFirma ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: subiendo ? null : () => _elegirImagen(esAdmin: esAdmin, id: id),
            icon: subiendo
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_rounded, size: 16),
            label: Text(tieneFirma ? 'Cambiar' : 'Subir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
      );
    }

    final listado = _listado!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'El boletín en PDF no se puede descargar si falta la firma del docente '
            'responsable o la del administrador. Sube aquí una imagen de cada firma '
            '(recorte de una firma escaneada o foto, fondo claro).',
            style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
          ),
        ),
        const Text('Administrador', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        if (listado.admin != null)
          _tarjetaFirma(
            nombre: listado.admin!.nombre,
            etiqueta: 'Firma del director(a) en el boletín',
            tieneFirma: listado.admin!.tieneFirma,
            esAdmin: true,
            id: listado.admin!.id,
          )
        else
          const Text('No se encontró una cuenta de administrador.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        const Text('Docentes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        if (listado.docentes.isEmpty)
          const Text('Aún no hay docentes registrados.', style: TextStyle(color: AppColors.textSecondary))
        else
          ...listado.docentes.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _tarjetaFirma(
                  nombre: d.nombre,
                  etiqueta: 'Firma en los boletines de sus estudiantes',
                  tieneFirma: d.tieneFirma,
                  esAdmin: false,
                  id: d.id,
                ),
              )),
      ],
    );
  }
}
