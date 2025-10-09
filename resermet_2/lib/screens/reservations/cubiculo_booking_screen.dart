// lib/screens/reservations/cubiculo_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:resermet_2/models/cubiculo.dart';
import 'package:resermet_2/utils/app_colors.dart';

import 'package:resermet_2/screens/reservations/reservation_form_cubiculo.dart';


class CubiculoBookingScreen extends StatelessWidget {
  final Cubiculo cubiculo;

  // Requiere el cubículo seleccionado para la reserva
  const CubiculoBookingScreen({
    super.key,
    required this.cubiculo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservar ${cubiculo.nombre}'),
        backgroundColor: AppColors.unimetBlue,
        foregroundColor: Colors.white,
      ),
      // Usaremos un SingleChildScrollView para asegurar que el formulario quepa
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildCubiculoInfoCard(context),

            const SizedBox(height: 20),

            const Text(
              'Detalles de la Reserva',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.unimetOrange,
              ),
            ),
            const SizedBox(height: 10),


            const Center(

            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCubiculoInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.meeting_room, color: AppColors.unimetBlue, size: 30),
        title: Text(
          cubiculo.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Ubicación: ${cubiculo.ubicacion} | Capacidad: ${cubiculo.capacidad}'),
        trailing: Chip(
          label: Text(cubiculo.estado),
          backgroundColor: Colors.green.shade100,
          labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}