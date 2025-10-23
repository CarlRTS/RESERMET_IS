import 'package:flutter/material.dart';
import 'package:resermet_2/screens/reservations/reservation_form_console.dart';
import 'package:resermet_2/screens/reservations/reservation_form_equipment.dart';
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/screens/reservations/reservation_form_cubiculo.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  // Función para verificar si es fin de semana
  bool _esFinDeSemana() {
    final now = DateTime.now();
    // 6 = Sábado, 7 = Domingo
    return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }

  // Widget auxiliar para las tarjetas de artículos
  Widget _buildArticleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget formScreen,
  }) {
    final esFinDeSemana = _esFinDeSemana();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: esFinDeSemana ? Colors.grey[300] : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: esFinDeSemana
                ? Colors.grey.withOpacity(0.3)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: esFinDeSemana ? Colors.grey : color,
            size: 30,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.unimetBlue,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (esFinDeSemana) const SizedBox(height: 5),
            if (esFinDeSemana)
              Text(
                'No disponible fines de semana',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: esFinDeSemana
            ? null // Deshabilitar el tap los fines de semana
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(title),
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      body: formScreen,
                    ),
                  ),
                );
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esFinDeSemana = _esFinDeSemana();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Título principal con indicador de fin de semana
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona el Artículo a Reservar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.unimetBlue,
                ),
              ),
              if (esFinDeSemana) // Banner de advertencia
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Las reservas no están disponibles los fines de semana',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Opción Cubículos
          _buildArticleCard(
            context,
            title: 'Cubículos de Estudio',
            subtitle: 'Espacios individuales o grupales en la biblioteca.',
            icon: Icons.meeting_room,
            color: Colors.lightBlue,
            formScreen: const ReservationFormCubiculo(),
          ),
          const SizedBox(height: 15),

          // Opción Consolas
          _buildArticleCard(
            context,
            title: 'Consolas de Videojuegos',
            subtitle: 'Reserva de consolas en el Decanato de estudiantes.',
            icon: Icons.gamepad,
            color: Colors.green,
            formScreen: const ReservationFormConsole(),
          ),
          const SizedBox(height: 15),

          // Opción Artículos Deportivos
          _buildArticleCard(
            context,
            title: 'Artículos Deportivos',
            subtitle:
                'Balones, raquetas y otros equipos en la Dirección de Deportes.',
            icon: Icons.sports_baseball,
            color: AppColors.unimetOrange,
            formScreen: const ReservationFormEquipment(),
          ),
        ],
      ),
    );
  }
}
