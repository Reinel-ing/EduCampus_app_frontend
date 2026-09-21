import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  String _rolSeleccionado = "estudiante";
  bool _isLoading = false;

  void _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Llamada a nuestro ApiService
      final resultado = await ApiService.registrarUsuario(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        rol: _rolSeleccionado,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Usuario registrado con éxito en EduCampus!"),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _nombreController.clear();
        _correoController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado["message"]),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro - EduCampus"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Crear Nueva Cuenta",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 10),
              const Text(
                "Recuerda que el correo debe pertenecer obligatoriamente al dominio @gmail.com",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre completo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? "Ingresa tu nombre" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico (@gmail.com)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingresa un correo";
                  }
                  if (!value.toLowerCase().endsWith("@gmail.com")) {
                    return "Solo se permiten cuentas con dominio @gmail.com";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(
                  labelText: "Rol en la plataforma",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: "estudiante", child: Text("Estudiante")),
                  DropdownMenuItem(value: "profesor", child: Text("Profesor")),
                  DropdownMenuItem(value: "administrador", child: Text("Administrador")),
                ],
                onChanged: (value) {
                  setState(() {
                    _rolSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _registrar,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Registrarse", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}