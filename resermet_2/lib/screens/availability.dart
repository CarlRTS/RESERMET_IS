import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// 🗺️ Pantalla de Disponibilidad y Ubicación (NUEVA)

class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  // Datos simulados de cubículos
  final List<Map<String, dynamic>> cubicles = const [
    {
      'name': 'Cubículo A-1 (Ind.)',
      'location': 'Biblioteca (Piso 1)',
      'available': true,
      'capacity': '1 persona',
    },
    {
      'name': 'Cubículo B-4 (Grup.)',
      'location': 'Biblioteca (Piso 2)',
      'available': false,
      'capacity': '4 personas',
    },
    {
      'name': 'Cubículo C-10 (Ind.)',
      'location': 'Edif. Postgrado',
      'available': true,
      'capacity': '1 persona',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
          child: Text(
            'Disponibilidad y Ubicación 📍',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.unimetBlue,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Consulta el estado en tiempo real de los cubículos.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: cubicles.length,
            itemBuilder: (context, index) {
              final cubicle = cubicles[index];
              final isAvailable = cubicle['available'] as bool;
              final statusColor = isAvailable ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: statusColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Icon(
                    isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: statusColor,
                    size: 35,
                  ),
                  title: Text(
                    cubicle['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.unimetBlue,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Ubicación: ${cubicle['location']}'),
                      Text('Capacidad: ${cubicle['capacity']}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      isAvailable ? 'Disponible' : 'Ocupado',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    backgroundColor: statusColor,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ver detalles del mapa para ${cubicle['name']}',
                        ),
                        backgroundColor: AppColors.unimetBlue,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}