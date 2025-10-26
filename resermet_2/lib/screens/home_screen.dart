import 'package:flutter/material.dart';
import 'package:resermet_2/screens/reservations/cubiculo_booking_screen.dart';
import 'package:resermet_2/screens/reservations/reservation_form_cubiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_reservations.dart';
import 'reservations/reservation_screen.dart';
import 'admin/admin_home_screen.dart';
import 'admin/cubiculos_list_screen.dart';
import 'login.dart';
import 'registro.dart';
import 'package:resermet_2/ui/theme/app_theme.dart';
import 'package:resermet_2/screens/reservations/reservation_form_equipment.dart';
import 'package:resermet_2/screens/reservations/reservation_form_console.dart';
import 'package:resermet_2/screens/user_profile_screen.dart'; // 👈 NUEVO IMPORT

// --- Pantalla Principal (Con Navegación Inferior) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  // Función para verificar si el usuario es administrador
  Future<void> _checkAdminRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('usuario')
            .select('rol')
            .eq('id_usuario', user.id)
            .maybeSingle();

        if (response != null) {
          final userData = response as Map<String, dynamic>;
          setState(() {
            _isAdmin = userData['rol'] == 'administrador';
          });
        }
      }
    } catch (e) {
      print('Error verificando rol de administrador: $e');
    }
  }

  // Lista de las pantallas (sin admin si no es administrador)
  List<Widget> get _widgetOptions {
    final screens = <Widget>[
      const HomeScreen(),
      const BookingScreen(),
      const MyBookingsScreen(),
    ];

    if (_isAdmin) {
      screens.add(const AdminHomeScreen());
    }

    return screens;
  }

  // Ítems del bottom navigation (sin admin si no es administrador)
  List<BottomNavigationBarItem> get _bottomNavItems {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_rounded),
        label: 'Reservar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_rounded),
        label: 'Mis Reservas',
      ),
    ];

    if (_isAdmin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Admin',
        ),
      );
    }

    return items;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 💡 FUNCIÓN DE CERRAR SESIÓN (LOGOUT)
  Future<void> _signOut() async {
    final cs = Theme.of(context).colorScheme;
    try {
      await Supabase.instance.client.auth.signOut();
      // Redirigir al login después de cerrar sesión
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.message}'),
          backgroundColor: cs.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: cs.error,
        ),
      );
    }
  }

  // 👇 Navegar a Mi Perfil
  void _goToMyProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RESERMET'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Mi Perfil',
            onPressed: _goToMyProfile, // 👈 acceso rápido a perfil
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text(
                    '¿Estás seguro que deseas cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _signOut();
              }
            },
          ),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(0.55),
        backgroundColor: cs.surface,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}

// 🏠 Pantalla de Inicio (Limpia)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // titulo
          Text(
            'Bienvenido a UNIMET Reservas',
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tu portal para reservar cubículos, equipos deportivos y más.',
            style: text.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(.75),
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta de instrucciones (única)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary.withOpacity(.25)),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 36,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Cómo usar la app para reservar',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1️⃣ En el menú inferior, toca la pestaña "Reservar".\n\n'
                    '2️⃣ Elige el tipo de reserva que deseas:\n'
                    '   • Cubículos de estudio\n'
                    '   • Equipos deportivos\n'
                    '   • Sala Gamer\n\n'
                    '3️⃣ Completa el formulario con los datos requeridos (hora, duración y propósito).\n\n'
                    '4️⃣ Confirma la reserva y revisa su estado en la pestaña "Mis Reservas".\n\n'
                    '5️⃣ Preséntate en el lugar asignado con tu carnet para validar el uso del espacio o artículo.',
                    style: text.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Consejo: puedes consultar tus horarios y cancelaciones desde "Mis Reservas".',
                            style: text.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Últimas noticias
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimas noticias',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.fiber_new_rounded, color: cs.primary),
            title: const Text('Nuevos cubículos disponibles en Biblioteca.'),
            subtitle: Text(
              '2 de Octubre, 2025',
              style: text.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(.65),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }
}
