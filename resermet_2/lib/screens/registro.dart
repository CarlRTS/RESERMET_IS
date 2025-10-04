

import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para capturar el texto de los formularios
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Clave global para manejar la validación del formulario
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Liberar recursos
    _emailController.dispose();
    _carnetController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    // 1. Validar el formulario (chequea los validadores de cada campo)
    if (_formKey.currentState!.validate()) {

      // 2. Realiza la validación de coincidencia de contraseñas
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Las contraseñas no coinciden.')),
        );
        return; // Detiene el proceso
      }

      // 3. Si todo es válido:
      final email = _emailController.text;

      print('✅ Registro exitoso para: Email=$email');

      // Parte de la api

      // Feedback visual y navegación de regreso al Login (simulando un registro exitoso)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuenta creada para $email!')),
      );
      Navigator.pop(context); // Vuelve a la pantalla de Login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta Resermet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey, // Vincula la clave de validación al formulario
          child: Column(
            children: <Widget>[
              const Text(
                'Completa tus datos para empezar a reservar.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // 1. Campo de Correo UNIMET
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo UNIMET',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.toLowerCase().endsWith('@correo.unimet.edu.ve')) {
                    return 'Ingrese un correo UNIMET válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Campo de Carnet
              TextFormField(
                controller: _carnetController,
                decoration: const InputDecoration(
                  labelText: 'Carnet (Ej: 2023141223)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 8) {
                    return 'Ingrese un número de carnet válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. Campo de Contraseña
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 4. Campo de Verificación de Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: Icon(Icons.lock_reset),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme su contraseña.';
                  }
                  // La validación de coincidencia estricta se hace en _submitRegistration
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Botón de Registrarse
              ElevatedButton(
                onPressed: _submitRegistration,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('CREAR CUENTA', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}