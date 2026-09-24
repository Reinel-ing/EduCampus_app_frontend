// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/colores_app.dart';
import '../../services/api_config.dart';
import '../../services/servicio_auth.dart';
import '../../services/servicio_notificaciones_backend.dart';

String _telefonoWhatsapp(String telefono) {
  final digitos = telefono.replaceAll(RegExp(r'\D'), '');
  if (digitos.startsWith('57') && digitos.length == 12) return digitos;
  if (digitos.length == 10) return '57$digitos';
  return digitos;
}

void _abrirChatsWhatsapp(List<AvisoWhatsapp> avisos) {
  for (final aviso in avisos) {
    final telefono = _telefonoWhatsapp(aviso.telefono);
    if (telefono.isEmpty) continue;
    final url = 'https://wa.me/$telefono?text=${Uri.encodeComponent(aviso.mensaje)}';
    html.window.open(url, '_blank');
  }
}

class _CursoDocente {
  final int id;
  final String title;

  const _CursoDocente({required this.id, required this.title});
}

class FinalizarClaseScreen extends StatefulWidget {
  const FinalizarClaseScreen({super.key});

  @override
  State<FinalizarClaseScreen> createState() => _FinalizarClaseScreenState();
}

class _FinalizarClaseScreenState extends State<FinalizarClaseScreen> {
  List<_CursoDocente> _cursos = [];
  int? _cursoSeleccionado;
  bool _cargandoCursos = true;
  bool _enviando = false;
  String? _errorMensaje;
  String? _mensajeExito;

  @override
  void initState() {
    super.initState();
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    final sesion = AuthService().sesionActual;

    if (sesion == null) {
      setState(() => _cargandoCursos = false);
      return;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cursos/').replace(
        queryParameters: {'instructor_id': sesion.usuarioId.toString()},
      );
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
        setState(() {
          _cursos = datos
              .map((c) => _CursoDocente(id: c['id'] as int, title: c['title'] as String))
              .toList();
          _cursoSeleccionado = _cursos.isNotEmpty ? _cursos.first.id : null;
          _cargandoCursos = false;
        });
      } else {
        setState(() => _cargandoCursos = false);
      }
    } catch (_) {
      setState(() => _cargandoCursos = false);
    }
  }

  Future<void> _avisarRecogida() async {
    if (_cursoSeleccionado == null) return;

    setState(() {
      _enviando = true;
      _errorMensaje = null;
      _mensajeExito = null;
    });

    try {
      final resultado = await NotificacionesBackendService().avisarRecogida(_cursoSeleccionado!);

      if (!mounted) return;

      if (resultado.whatsapp.isNotEmpty) {
        _abrirChatsWhatsapp(resultado.whatsapp);
      }

      setState(() {
        _enviando = false;
        _mensajeExito = resultado.acudientesNotificados > 0
            ? 'Aviso enviado a ${resultado.acudientesNotificados} acudiente(s)'
                '${resultado.whatsapp.isNotEmpty ? '. Se abrió un chat de WhatsApp por cada uno: solo falta darle "Enviar" en cada pestaña.' : '.'}'
            : 'No hay acudientes registrados para notificar en este curso.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorMensaje = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorMensaje = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
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
                      Text('Ya pueden recoger a los estudiantes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      SizedBox(height: 4),
                      Text(
                        'Elige el curso que acaba de terminar. Se avisa al instante '
                        'solo a los acudientes de los estudiantes de ese curso.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_cargandoCursos)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_cursos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No tienes cursos asignados todavía.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else ...[
            const Text(
              'CURSO',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F7), borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _cursoSeleccionado,
                  isExpanded: true,
                  items: _cursos
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
                      .toList(),
                  onChanged: (v) => setState(() => _cursoSeleccionado = v),
                ),
              ),
            ),

            if (_errorMensaje != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF5C2C0)),
                ),
                child: Text(_errorMensaje!,
                    style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w600)),
              ),
            ],

            if (_mensajeExito != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Text(_mensajeExito!,
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _avisarRecogida,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.campaign_rounded),
                label: Text(_enviando ? 'Enviando...' : 'Avisar a los acudientes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
