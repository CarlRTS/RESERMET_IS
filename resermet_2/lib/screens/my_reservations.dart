import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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