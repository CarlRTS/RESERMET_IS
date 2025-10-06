import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
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

class CubiculoBookingScreen extends StatelessWidget {
  final Cubiculo cubiculo;

  const CubiculoBookingScreen({super.key, required this.cubiculo});

  Future<void> _handleReservation(BuildContext context) async {
    final CubiculoService service = CubiculoService();

    // 1. Crear una copia del cubículo con el estado cambiado a 'ocupado'
    final Cubiculo cubiculoOcupado = Cubiculo(
      idObjeto: cubiculo.idObjeto,
      nombre: cubiculo.nombre,
      estado: 'ocupado', // <<<<<< CAMBIO DE ESTADO
      idArea: cubiculo.idArea,
      ubicacion: cubiculo.ubicacion,
      capacidad: cubiculo.capacidad,
    );

    try {
      // 2. Llamar al servicio para actualizar la base de datos
      await service.updateCubiculo(cubiculoOcupado);

      // 3. Notificación de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Reserva de ${cubiculo.nombre} exitosa! Estado actualizado a OCUPADO.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // 4. Navegar hacia atrás dos veces: cerrar esta pantalla y forzar un refresh en AvailabilityScreen
      Navigator.of(context).pop();
      // Si la AvailabilityScreen es Stateful, al regresar se llamará a su initState o didChangeDependencies,
      // lo que debería disparar la recarga de datos.
    } catch (e) {
      // 5. Manejo de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar la reserva: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservar: ${cubiculo.nombre}'),
        backgroundColor: AppColors.unimetBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Confirmar Reserva para ${cubiculo.nombre}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.unimetBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ubicación: ${cubiculo.ubicacion} | Capacidad: ${cubiculo.capacidad} personas',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 30),

            // Formulario de Reserva (Simulación)
            const Text(
              'Detalles de la Reserva',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Campo de selección de fecha (simulado)
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: AppColors.unimetOrange,
              ),
              title: const Text('Fecha Seleccionada'),
              subtitle: const Text(
                'Hoy, 15:00 - 17:00 (Haga clic para cambiar)',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // TODO: Implementar DatePicker y TimePicker real
              },
            ),

            const SizedBox(height: 30),

            // Botón de Confirmación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Lógica real para enviar la reserva a Supabase
                  Navigator.of(context).pop(); // Cerrar la pantalla de reserva
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '¡Reserva de ${cubiculo.nombre} confirmada con éxito!',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_clock),
                label: const Text(
                  'Confirmar Reserva',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.unimetOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
