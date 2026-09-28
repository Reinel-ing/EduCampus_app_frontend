import 'package:flutter/material.dart';
import '../core/theme/colores_app.dart';

class LabeledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (!_focusNode.hasFocus) _focusNode.requestFocus();
          },
          child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B0B8), fontSize: 13.5),
            prefixIcon: Icon(widget.icon, size: 20, color: AppColors.textSecondary),
            filled: true,
            fillColor: const Color(0xFFEDEFF4),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD5D9E2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD5D9E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
          ),
        ),
      ],
    );
  }
}