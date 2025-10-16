// availability.dart
/*
import 'package:flutter/material.dart';
import 'package:resermet_2/screens/reservations/reservation_screen.dart';
import '../utils/app_colors.dart';
import '../models/cubiculo.dart'; // Importar el modelo Cubiculo
import '../services/cubiculo_service.dart'; // Importar el servicio
import 'package:flutter/material.dart';
// ¡IMPORTA LA NUEVA PANTALLA Creada!
import 'package:resermet_2/screens/reservations/cubiculo_booking_screen.dart'; // Asegúrate de que la ruta sea correcta


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
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => CubiculoBookingScreen(cubiculo: cubiculo),
            ),
          )
          .then((_) {
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
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.unimetBlue),
            ),
          )
        else if (_error.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ),
          )
        else if (_cubicles.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No hay cubículos registrados en la base de datos.'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _cubicles.length,
              itemBuilder: (context, index) {
                final cubicle = _cubicles[index];
                // Usar el campo 'estado' del modelo Cubiculo, asumiendo 'disponible' es el indicador.
                final isAvailable =
                    cubicle.estado.toLowerCase() == 'disponible';
                final statusColor = isAvailable ? Colors.green : Colors.red;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                      isAvailable
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
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
                        cubicle
                            .estado, // Mostrar el estado tal como viene de la DB
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
}*/

// availability.dart

// availability.dart

import 'dart:async'; // Necesario para StreamSubscription
import 'package:flutter/material.dart';
import 'package:resermet_2/screens/reservations/reservation_form_cubiculo.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Necesario para SupabaseClient
import 'package:resermet_2/screens/reservations/reservation_screen.dart';
import '../utils/app_colors.dart';
import '../models/cubiculo.dart';
import '../services/cubiculo_service.dart';

// 🗺️ Pantalla de Disponibilidad y Ubicación (CON BASE DE DATOS y REALTIME)

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final CubiculoService _cubiculoService = CubiculoService();

  // 💡 PROPIEDADES REALTIME: Cliente y Suscripción
  final _client = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  List<Cubiculo> _cubicles = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchCubicles();

    // 💡 CONFIGURACIÓN REALTIME: Suscribirse a cambios en la tabla 'cubiculo'
    // Cada vez que un cubículo se actualiza (estado cambia), se recarga la lista.
    _sub = _client
        .from('cubiculo')
    // Usa primaryKey: ['id_articulo'] para un canal más eficiente
        .stream(primaryKey: ['id_articulo'])
        .listen((_) {
      // Cuando la base de datos notifica un cambio, recargar los datos
      _fetchCubicles();
    });
  }

  // 💡 IMPORTANTE: Cancelar la suscripción al destruir el widget
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _fetchCubicles() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final cubicles = await _cubiculoService.getCubiculos();
      setState(() {
        // Muestra los cubículos que no están 'en_mantenimiento'
        _cubicles = cubicles.where((c) => c.estado != 'en_mantenimiento').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Fallo al cargar la disponibilidad: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleReservationTap(BuildContext context, Cubiculo cubicle) {
    if (cubicle.estado == 'disponible') {
      Navigator.push(
        context,
        MaterialPageRoute(
          // Pasa el objeto Cubiculo a la pantalla de reserva
          builder: (context) => ReservationFormCubiculo()
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cubículo no está disponible para reserva.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return Colors.green;
      case 'prestado':
        return Colors.red;
      case 'en_mantenimiento':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Disponibilidad de Cubículos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.unimetBlue,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Información en tiempo real. Toca para reservar.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // 🔄 Indicador de carga
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          // ❌ Indicador de error
          else if (_error.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchCubicles,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          // ✅ Lista de cubículos
          else if (_cubicles.isEmpty)
              const Center(
                child: Text('No hay cubículos disponibles o registrados.'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _cubicles.length,
                  itemBuilder: (context, index) {
                    final cubicle = _cubicles[index];
                    final isAvailable = cubicle.estado == 'disponible';
                    final statusColor = _getStatusColor(cubicle.estado);

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        // Borde sutil para indicar disponibilidad
                        side: isAvailable ? BorderSide(color: Colors.green.shade100, width: 2) : BorderSide.none,
                      ),
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading: Icon(
                          Icons.meeting_room,
                          color: isAvailable ? AppColors.unimetBlue : Colors.grey,
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
                            Text('Capacidad: ${cubicle.capacidad} personas'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            cubicle
                                .estado, // Mostrar el estado tal como viene de la DB
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: statusColor,
                        ),
                        // Al tocar, si está disponible, llama a la función de reserva
                        /*onTap: isAvailable
                            ? () => _handleReservationTap(context, cubicle)
                            : null, // Si está ocupado, no es clickeable*/
                      ),
                    );
                  },
                ),
              ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
