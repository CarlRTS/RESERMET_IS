// lib/screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'cubiculos_list_screen.dart';
import 'consolas_list_screen.dart';
import 'equipos_list_screen.dart';
import 'reservas_activas_screen.dart';
import 'users_list_screen.dart'; // ← NUEVO IMPORT

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _navigateToCubiculos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CubiculosListScreen()),
    );
  }

  void _navigateToConsolas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConsolasListScreen()),
    );
  }

  void _navigateToEquiposDeportivos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EquiposListScreen()),
    );
  }

  void _navigateToReservasActivas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReservasActivasScreen()),
    );
  }

  void _navigateToUsers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsersListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: const Color(0xFF0033A0),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestión de Recursos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0033A0),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Selecciona el módulo que deseas gestionar',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),

              _buildManagementCard(
                context,
                title: 'Cubículos de Estudio',
                subtitle: 'Gestionar espacios individuales o grupales',
                icon: Icons.meeting_room,
                color: const Color(0xFF0033A0),
                onTap: () => _navigateToCubiculos(context),
                available: true,
              ),
              const SizedBox(height: 20),

              _buildManagementCard(
                context,
                title: 'Consolas y Juegos',
                subtitle: 'Gestionar equipos del Centro de Diseño Digital',
                icon: Icons.gamepad,
                color: Colors.green,
                onTap: () => _navigateToConsolas(context),
                available: true,
              ),
              const SizedBox(height: 20),

              _buildManagementCard(
                context,
                title: 'Equipos Deportivos',
                subtitle: 'Gestionar material deportivo y equipos',
                icon: Icons.sports_baseball,
                color: Colors.orange,
                onTap: () => _navigateToEquiposDeportivos(context),
                available: true,
              ),
              const SizedBox(height: 20),

              _buildManagementCard(
                context,
                title: 'Reservas Activas',
                subtitle: 'Monitorear y finalizar reservas en curso',
                icon: Icons.schedule,
                color: Colors.blueAccent,
                onTap: () => _navigateToReservasActivas(context),
                available: true,
              ),
              const SizedBox(height: 20),

              // 🟦 NUEVA TARJETA: Usuarios
              _buildManagementCard(
                context,
                title: 'Usuarios',
                subtitle: 'Buscar y ver perfiles de estudiantes',
                icon: Icons.people_alt_rounded,
                color: Colors.purple,
                onTap: () => _navigateToUsers(context),
                available: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool available,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: available ? const Color(0xFF0033A0) : Colors.grey,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 5),
            Text(
              available ? '✅ Disponible' : '🔄 Próximamente',
              style: TextStyle(
                color: available ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: available ? const Color(0xFF0033A0) : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
