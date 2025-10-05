import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import 'my_reservations.dart';
import 'reservation_screen.dart';
import 'availability.dart';
import 'admin/admin_home_screen.dart'; // ← CAMBIADO EL IMPORT
import 'catalog_equipo_deportivo_screen.dart';
import 'admin/cubiculos_list_screen.dart';
import 'admin/admin_home_screen.dart';
import 'login.dart';
import 'registro.dart';

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
    AvailabilityScreen(),
    AdminHomeScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 💡 FUNCIÓN DE CERRAR SESIÓN (LOGOUT)
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      // El AuthGate en main.dart detectará este cambio y navegará a LoginScreen
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RESERMET')),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Ubicación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.unimetBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// -------------------------------------------------------------------

// 🏠 Pantalla de Inicio (Limpia)

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
                    '¡Reserva lo que necesitas!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Fila 1: Cubículo + Equipo Deportivo
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.findAncestorStateOfType<_MainScreenState>()?._onItemTapped(3);
                          },
                          icon: const Icon(Icons.meeting_room),
                          label: const Text('Reserva tu Cubículo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CatalogEquipoDeportivoScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sports_soccer),
                          label: const Text('Reserva tu Equipo Deportivo'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Fila 2: Sala Gamer (placeholder por ahora)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: cuando hagas el catálogo de consolas/sala gamer, navega allí
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sala Gamer: próximamente'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sports_esports),
                          label: const Text('Reserva en la Sala Gamer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimas Noticias',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.unimetBlue,
                ),
              ),
            ],
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


