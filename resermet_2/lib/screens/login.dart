// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
// Asegúrate de que este archivo exista para que la navegación funcione
import 'registro.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para leer los datos de los campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Función donde irá la lógica de autenticación
  void _performLogin() {
    final email = _emailController.text;
    final password = _passwordController.text;

    // TODO:
    // Aquí iría la llamada a tu servicio de API/Backend para autenticar al usuario.

    print('Intentando iniciar sesión con: Email=$email, Password=$password');

    // Ejemplo de feedback visual temporal:
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Autenticando... $email')),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Campo de Email (Ahora con el controlador asignado)
            TextField(
              controller: _emailController, // <<<--- CORREGIDO
              decoration: const InputDecoration(labelText: 'Correo UNIMET'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Campo de Contraseña (Ahora con el controlador asignado)
            TextField(
              controller: _passwordController, // <<<--- CORREGIDO
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 30),

            // Botón de Iniciar Sesión
            ElevatedButton(
              onPressed: _performLogin,
              child: const Text('INGRESAR', style: TextStyle(fontSize: 18)),
            ),

            // Botón de Navegación a Registro
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navega a la nueva pantalla de registro
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
          ],
        ),
      ),
    );
  }
}