import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/reserva.dart';
import '../services/reserva_service.dart';

//  Pantalla de Planificación de Disponibilidad (Agrupada por Artículo)

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final ReservaService _reservaService = ReservaService();
  late Future<List<Reserva>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    // La carga inicial se hará en el build para forzar la sincronización
  }

  Future<List<Reserva>> _fetchReservations() async {
    try {
      //  ADVERTENCIA: Esto trae TODAS las reservas del sistema para la planificación global.
      return await _reservaService.getMyReservations();
    } catch (e) {
      print('Error loading reservations: $e');
      return [];
    }
  }

  // Agrupa las reservas por el nombre del artículo
  Map<String, List<Reserva>> _groupReservations(List<Reserva> allReservations) {
    final Map<String, List<Reserva>> grouped = {};
    for (var reserva in allReservations) {
      final key = reserva.nombreArticulo;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(reserva);
    }
    return grouped;
  }

  // Helper para formatear la hora (ej: 14:00 -> 2:00 PM)
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // obtener el color de OCUPACIÓN
  Color _getOccupiedColor(String status) {
    switch (status.toLowerCase()) {
      case 'activa':
      case 'pendiente':
        return Colors.red.shade700; // Rojo/Naranja fuerte para OCUPADO
      default:
        return Colors.grey;
    }
  }

  //  icono del tipo de articulo
  IconData _getArticleIcon(String articleName) {
    final lowerName = articleName.toLowerCase();
    if (lowerName.contains('consola') || lowerName.contains('ps5') || lowerName.contains('xbox')) {
      return Icons.videogame_asset;
    }
    if (lowerName.contains('cubículo')) {
      return Icons.meeting_room;
    }
    if (lowerName.contains('balón') || lowerName.contains('raqueta')) {
      return Icons.sports_soccer;
    }
    return Icons.category;
  }


  @override
  Widget build(BuildContext context) {
    // 💡 SOLUCIÓN DE SINCRONIZACIÓN
    _reservationsFuture = _fetchReservations();

    return Container(
      // 💡 Fondo degradado para un toque más moderno
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.unimetLightGray.withOpacity(0.8)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Disponibilidad de Artículos',
              style: TextStyle(
                fontSize: 26, // 💡 Fuente más grande
                fontWeight: FontWeight.w900, //  Más peso
                color: AppColors.unimetBlue,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Consulta horarios ocupados para una planificación óptima.',
              style: TextStyle(fontSize: 15, color: Colors.black54, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<Reserva>>(
                future: _reservationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.unimetOrange)); //  Color del indicador
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                  }

                  final List<Reserva> allBookings = snapshot.data ?? [];

                  final activeBookings = allBookings.where((b) =>
                  b.estado.toLowerCase() == 'activa' || b.estado.toLowerCase() == 'pendiente'
                  ).toList();

                  final groupedBookings = _groupReservations(activeBookings);

                  if (groupedBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade400),
                          const SizedBox(height: 10),
                          const Text('¡Todo disponible para préstamo!', style: TextStyle(fontSize: 18, color: Colors.black54)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: groupedBookings.keys.length,
                    itemBuilder: (context, index) {
                      final articleName = groupedBookings.keys.elementAt(index);
                      final reservations = groupedBookings[articleName]!;
                      final articleIcon = _getArticleIcon(articleName);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        // 💡 Aplicamos estilo de tarjeta más bonito con sombra
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect( // Para que los hijos respeten el borde
                            borderRadius: BorderRadius.circular(15),
                            child: ExpansionTile(
                              collapsedBackgroundColor: Colors.white,
                              backgroundColor: AppColors.unimetLightGray.withOpacity(0.8),
                              leading: Icon(articleIcon, color: AppColors.unimetOrange, size: 30), //  Ícono dinámico
                              title: Text(
                                articleName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.unimetBlue,
                                    fontSize: 17
                                ),
                              ),
                              subtitle: Text('${reservations.length} rangos de hora ocupados.'),
                              children: reservations.map((booking) {
                                final timeRange = '${_formatTime(booking.fechaInicio)} - ${_formatTime(booking.fechaFin)}';
                                final date = '${booking.fechaInicio.day}/${booking.fechaInicio.month}/${booking.fechaInicio.year}';

                                return ListTile(
                                  contentPadding: const EdgeInsets.only(left: 30, right: 16),
                                  leading: Icon(Icons.lock_clock, color: _getOccupiedColor(booking.estado)), // 💡 Ícono de candado/reloj
                                  title: Text(
                                    'OCUPADO: $timeRange',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _getOccupiedColor(booking.estado),
                                    ),
                                  ),
                                  subtitle: Text('Fecha: $date | Estado: ${booking.estado}'),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}