import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// --- Pantalla Principal (Con Navegación Inferior) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de las pantallas
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    BookingScreen(),
    MyBookingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservas UNIMET 💙💛')),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Reservar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mis Reservas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            AppColors.unimetBlue, // Icono y texto seleccionado en azul
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// -------------------------------------------------------------------

// 🏠 Pantalla de Inicio

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Bienvenido a UNIMET Reservas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.unimetBlue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu portal para reservar cubículos, consolas y otros recursos académicos.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 30),
          // Tarjeta de información/acción
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.school,
                    size: 50,
                    color: AppColors.unimetOrange,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '¡Reserva tu Cubículo ahora!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Simular navegación a la pantalla de reservar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navegando a Reservar...'),
                        ),
                      );
                      // En una app real, cambiarías el índice del BottomNavigationBar del MainScreen.
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Comenzar Reserva'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Últimas Noticias',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.unimetBlue,
            ),
          ),
          const ListTile(
            leading: Icon(Icons.fiber_new, color: AppColors.unimetBlue),
            title: Text('Nuevos cubículos disponibles en Biblioteca.'),
            subtitle: Text('2 de Octubre, 2025'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------

// 🗓️ Pantalla de Reservar

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Selecciona el Artículo a Reservar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.unimetBlue,
            ),
          ),
          const SizedBox(height: 20),
          // Opción Cubículos
          _buildArticleCard(
            context,
            title: 'Cubículos de Estudio',
            subtitle: 'Espacios individuales o grupales en la biblioteca.',
            icon: Icons.meeting_room,
            color: Colors.lightBlue,
            onTap: () {
              _showReservationAlert(context, 'Cubículos');
            },
          ),
          const SizedBox(height: 15),
          // Opción Consolas/Equipos
          _buildArticleCard(
            context,
            title: 'Consolas / Equipos',
            subtitle:
                'Reserva de consolas en el Centro de Diseño Digital (CDD).',
            icon: Icons.gamepad,
            color: Colors.green,
            onTap: () {
              _showReservationAlert(context, 'Consolas');
            },
          ),
          const SizedBox(height: 15),
          // Opción Otros (Ej: Salas de Reunión)
          _buildArticleCard(
            context,
            title: 'Salas de Reunión',
            subtitle: 'Salas para presentaciones o trabajos en equipo.',
            icon: Icons.people,
            color: Colors.orange,
            onTap: () {
              _showReservationAlert(context, 'Salas de Reunión');
            },
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para las tarjetas de artículos
  Widget _buildArticleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: color.withValues(),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.unimetBlue,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Función para mostrar un diálogo simulado de reserva
  void _showReservationAlert(BuildContext context, String itemType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reservar $itemType'),
        content: const Text(
          'Aquí iría el formulario para seleccionar fecha, hora y ver disponibilidad.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('¡Reserva de $itemType en progreso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------

// 📝 Pantalla de Mis Reservas

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de reservas simuladas
    final List<Map<String, dynamic>> simulatedBookings = [
      {
        'item': 'Cubículo B-4',
        'date': 'Vie, 4 de Oct',
        'time': '14:00 - 16:00',
        'status': 'Activa',
        'color': Colors.green,
      },
      {
        'item': 'Consola PS5 (CDD)',
        'date': 'Lun, 7 de Oct',
        'time': '10:00 - 11:30',
        'status': 'Pendiente',
        'color': Colors.orange,
      },
      {
        'item': 'Cubículo A-12',
        'date': 'Ayer',
        'time': '16:00 - 18:00',
        'status': 'Completada',
        'color': Colors.grey,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Mis Reservas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.unimetBlue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Consulta el estado de tus reservas actuales y pasadas.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: simulatedBookings.length,
              itemBuilder: (context, index) {
                final booking = simulatedBookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.book_online,
                      color: AppColors.unimetBlue,
                      size: 30,
                    ),
                    title: Text(
                      booking['item']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.unimetBlue,
                      ),
                    ),
                    subtitle: Text('${booking['date']} | ${booking['time']}'),
                    trailing: Chip(
                      label: Text(booking['status']!),
                      backgroundColor: booking['color']!.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: booking['color'] as Color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Detalles de la reserva: ${booking['item']}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
