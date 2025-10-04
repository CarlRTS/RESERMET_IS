// lib/screens/inicio.dart

import 'package:flutter/material.dart';
// Asegúrate de que este nombre de archivo sea correcto:
import 'login.dart'; // <<<--- ASUMO que el archivo de login se llama 'login_screen.dart'
// NOTA: Si tu archivo de login se llama 'login.dart', el import sería:
// import 'login.dart';


// 1. CLASE PRINCIPAL: El StatefulWidget
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}


// 2. CLASE DEL ESTADO (donde está el método build)
class _MainScreenState extends State<MainScreen> {
  // AÑADIDO: Declaración de la variable que controla la pestaña activa
  int _selectedIndex = 0;

  // AÑADIDO: Función que se llama cuando se toca una pestaña del BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === APPBAR CON EL BOTÓN DE INICIAR SESIÓN Y NAVEGACIÓN ===
      appBar: AppBar(
        title: const Text('Reservas UNIMET 💙💛'),
        // La propiedad 'actions' contiene los widgets del lado derecho
        actions: <Widget>[
          TextButton(
            onPressed: () {
              // Lógica para navegar a la pantalla de inicio de sesión
              Navigator.push(
                context,
                // Corregido: Llamamos a LoginScreen
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              'INICIAR SESIÓN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      // =========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Bienvenido a UNIMET Reservas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu portal para reservar cubículos, consolas y otros recursos académicos.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Tarjeta de Reserva de Cubículo
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary, // Usa el amarillo del tema
                    ),
                    const SizedBox(height: 8),
                    const Text('¡Reserva tu Cubículo ahora!', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    // Usa el ElevatedButton con el estilo que definiste en main.dart
                    ElevatedButton(
                      onPressed: () {
                        print('Comenzar Reserva presionado');
                      },
                      child: const Text('Comenzar Reserva'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Últimas Noticias',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Noticia de Ejemplo
            const ListTile(
              leading: Icon(Icons.article),
              title: Text('Nuevos cubículos disponibles en Biblioteca.'),
              subtitle: Text('2 de Octubre, 2025'),
            ),
          ],
        ),
      ),

      // La barra de navegación inferior (BottomNavigationBar)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Mis Reservas',
          ),
        ],
        // Corregido: Usa la variable de estado declarada
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Color primario (Azul)
        // Corregido: Usa la función de manejo de eventos
        onTap: _onItemTapped,
      ),
    );
  }
}
// <<<--- Asegúrate de que las llaves de cierre de la clase y el archivo estén aquí