import 'package:flutter/material.dart';
// import 'package:resermet_2/models/cubiculo.dart'; // Eliminado: No se usa aquí
import 'package:resermet_2/screens/reservations/reservation_form_console.dart';
import 'package:resermet_2/screens/reservations/reservation_form_equipment.dart';
// import 'package:resermet_2/services/cubiculo_service.dart'; // Eliminado: No se usa aquí
import 'package:resermet_2/utils/app_colors.dart';
import 'package:resermet_2/screens/reservations/reservation_form_cubiculo.dart';

// 🗓️ Pantalla de Reservar (Menú de Selección)

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  // Widget auxiliar para las tarjetas de artículos
  // **CORREGIDO:** El parámetro 'onTap' se cambió a 'formScreen' (Widget) para estandarizar la navegación.
  Widget _buildArticleCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Widget formScreen, // Ahora espera el Widget del formulario
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.unimetBlue,
            fontSize: 18,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(title),
                  backgroundColor: color, // Usamos el color del artículo en el AppBar
                  foregroundColor: Colors.white,
                ),
                body: formScreen, // Navegar directamente al formulario
              ),
            ),
          );
        },
      ),
    );
  }

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
            formScreen: const ReservationFormCubiculo(), // **CORREGIDO**
          ),
          const SizedBox(height: 15),

          // Opción Consolas
          _buildArticleCard(
            context,
            title: 'Consolas de Videojuegos',
            subtitle: 'Reserva de consolas en el Decanato de estudiantes.',
            icon: Icons.gamepad,
            color: Colors.green,
            formScreen: const ReservationFormConsole(), // **CORREGIDO**
          ),
          const SizedBox(height: 15),

          // Opción Artículos Deportivos
          _buildArticleCard(
            context,
            title: 'Artículos Deportivos',
            subtitle:
            'Balones, raquetas y otros equipos en la Dirección de Deportes.',
            icon: Icons.sports_baseball, // Mejor icono para deportes
            color: AppColors.unimetOrange,
            formScreen: const ReservationFormEquipment(), // **CORREGIDO**
          ),
        ],
      ),
    );
  }
}

