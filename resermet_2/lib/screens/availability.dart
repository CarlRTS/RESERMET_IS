// availability.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/cubiculo.dart'; // Importar el modelo Cubiculo
import '../services/cubiculo_service.dart'; // Importar el servicio
import 'reservation_screen.dart'; // Importar la pantalla de reserva específica

// 🗺️ Pantalla de Disponibilidad y Ubicación (CON BASE DE DATOS)

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final CubiculoService _cubiculoService = CubiculoService();
  List<Cubiculo> _cubicles = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchCubicles();
  }

  Future<void> _fetchCubicles() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      // 💡 Llamada real al servicio para obtener datos de Supabase
      final cubicles = await _cubiculoService.getCubiculos();
      setState(() {
        _cubicles = cubicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar cubículos: $e';
        _isLoading = false;
      });
      print(_error);
    }
  }

// Función para manejar la reserva (CON NAVEGACIÓN REAL Y RECARGA)
  void _handleReservationTap(BuildContext context, Cubiculo cubiculo) {
    if (cubiculo.estado.toLowerCase() == 'disponible') {
      // 1. Navegar y esperar a que la pantalla de reserva se cierre
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CubiculoBookingScreen(cubiculo: cubiculo),
        ),
      ).then((_) {
        // 2. Cuando se vuelve a esta pantalla (luego del pop), recargar la lista
        _fetchCubicles();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cubículo no está disponible para reserva.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: AppColors.unimetBlue),
          ))
        else if (_error.isNotEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(_error, style: const TextStyle(color: Colors.red)),
          ))
        else if (_cubicles.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No hay cubículos registrados en la base de datos.'),
            ))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _cubicles.length,
                itemBuilder: (context, index) {
                  final cubicle = _cubicles[index];
                  // Usar el campo 'estado' del modelo Cubiculo, asumiendo 'disponible' es el indicador.
                  final isAvailable = cubicle.estado.toLowerCase() == 'disponible';
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
                        cubicle.nombre,
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
                          Text('Ubicación: ${cubicle.ubicacion}'),
                          // La capacidad es un 'int', lo mostramos sin '.toString()' implícito
                          Text('Capacidad: ${cubicle.capacidad} personas'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          cubicle.estado, // Mostrar el estado tal como viene de la DB
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: statusColor,
                      ),
                      // Al tocar, si está disponible, llama a la función de reserva
                      onTap: isAvailable
                          ? () => _handleReservationTap(context, cubicle)
                          : null, // Si está ocupado, no es clickeable
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