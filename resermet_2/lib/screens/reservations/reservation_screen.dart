import 'package:flutter/material.dart';
import 'package:resermet_2/screens/reservations/reservation_form_console.dart';
import 'package:resermet_2/screens/reservations/reservation_form_equipment.dart';
import '../../utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reservation_form_console.dart';

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
            subtitle: 'Reserva de consolas en el Decanato de estudiantes',
            icon: Icons.gamepad,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationFormConsole(),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          // Opción Otros (Ej: Salas de Reunión)
          _buildArticleCard(
            context,
            title: 'Articulos deportivos',
            subtitle:
                'Articulos deportivos entre otros en el Decanato de estudiantes',
            icon: Icons.people,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationFormEquipment(),
                ),
              );
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
