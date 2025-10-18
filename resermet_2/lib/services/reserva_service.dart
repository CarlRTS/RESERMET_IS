import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_service.dart';
import '../models/reserva.dart';
import '../models/articulo.dart';
import 'cubiculo_service.dart';
import 'consola_service.dart';
import 'equipo_deportivo_service.dart';

class ReservaService with BaseService {
  final _cubiculoService = CubiculoService();
  final _consolaService = ConsolaService();
  final _equipoService = EquipoDeportivoService();

  // Obtiene el Articulo concreto (Cubículo, Consola o Equipo) según su ID
  Future<Articulo> _getArticuloById(int idArticulo) async {
    final cubiculos = await _cubiculoService.getCubiculos();
    try { return cubiculos.firstWhere((e) => e.idObjeto == idArticulo); } catch (_) {}

    final consolas = await _consolaService.getConsolas();
    try { return consolas.firstWhere((e) => e.idObjeto == idArticulo); } catch (_) {}

    final equipos = await _equipoService.getEquiposDeportivos();
    try { return equipos.firstWhere((e) => e.idObjeto == idArticulo); } catch (_) {}

    throw Exception('Tipo de artículo no reconocido para ID: $idArticulo');
  }

  // Obtener reservas del usuario actual
  Future<List<Reserva>> getMyReservations() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('reserva')
          .select('*')
          .eq('id_usuario', userId) // columna en tu BD
          .order('inicio', ascending: false);

      final List<Reserva> reservas = [];
      for (final item in response) {
        final int idArticulo = item['id_articulo'] as int;
        try {
          final Articulo articulo = await _getArticuloById(idArticulo);
          reservas.add(Reserva.fromSupabase(item, articulo));
        } catch (_) {
          // no romper si un artículo ya no existe o falló su carga
        }
      }
      return reservas;
    } catch (e) {
      throw Exception('Error al cargar sus reservas');
    }
  }

  // Crear nueva reserva (NO cambia estado del artículo)
  Future<Reserva> createReserva(Reserva reserva) async {
    try {
      final response = await supabase
          .from('reserva')
          .insert(reserva.toJson())
          .select()
          .single();

      // 👉 No tocamos articulo.estado aquí. Se mantiene "disponible" si hay stock.
      return Reserva.fromSupabase(response, reserva.articulo);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear la reserva: ${e.message}');
    } catch (e) {
      throw Exception('Error desconocido al crear la reserva: $e');
    }
  }

  // Admin: reservas activas crudas
  Future<List<Map<String, dynamic>>> getReservasActivasRaw() async {
    final data = await supabase
        .from('reserva')
        .select(
          'id_reserva, id_articulo, id_usuario, inicio, fin, estado, articulo(nombre)',
        )
        .eq('estado', 'activa')
        .order('fin', ascending: true);

    return (data as List).cast<Map<String, dynamic>>();
  }

  // Finalizar reserva (NO fuerza estado del artículo)
  Future<void> finalizarReserva({
    required int idReserva,
    required int idArticulo,
  }) async {
    await supabase
        .from('reserva')
        .update({'estado': 'finalizada'})
        .eq('id_reserva', idReserva);

  }
}
