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

  // Función auxiliar para obtener el Articulo completo a partir de su ID
  // Se necesita cargar el objeto específico (Cubículo, Consola, Equipo)
  // ya que la consulta de reserva solo trae el 'articulo' base.
  Future<Articulo> _getArticuloById(int idArticulo) async {
    // Nota: Aunque es ineficiente hacer 3 llamadas si ya tenemos el ID,
    // es la forma más rápida de obtener el objeto concreto (p.ej. Cubiculo)
    // que necesita la lógica de la app.
    final cubiculos = await _cubiculoService.getCubiculos();
    try {
      return cubiculos.firstWhere((e) => e.idObjeto == idArticulo);
    } catch (_) {}

    final consolas = await _consolaService.getConsolas();
    try {
      return consolas.firstWhere((e) => e.idObjeto == idArticulo);
    } catch (_) {}

    final equipos = await _equipoService.getEquiposDeportivos();
    try {
      return equipos.firstWhere((e) => e.idObjeto == idArticulo);
    } catch (_) {}

    throw Exception('Tipo de artículo no reconocido para ID: $idArticulo');
  }

  // Obtener reservas del usuario actual
  Future<List<Reserva>> getMyReservations() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Obtener la lista de reservas
      final response = await supabase
          .from('reserva')
          .select('*')
          .eq('user_id', userId)
          .order('fecha_inicio', ascending: false);

      final List<Reserva> reservas = [];
      for (final item in response) {
        final int idArticulo = item['id_articulo'] as int;
        try {
          // 2. Obtener el objeto Articulo completo (Cubículo/Consola/Equipo)
          final Articulo articulo = await _getArticuloById(idArticulo);
          // 3. Crear el objeto Reserva con el Artículo completo
          reservas.add(Reserva.fromSupabase(item, articulo));
        } catch (e) {
          print('Error al obtener detalles del artículo $idArticulo: $e');
        }
      }
      return reservas;

    } catch (e) {
      print('Error obteniendo reservas: $e');
      throw Exception('Error al cargar sus reservas');
    }
  }

  // Crear nueva reserva
  Future<Reserva> createReserva(Reserva reserva) async {
    try {
      final response = await supabase
          .from('reserva')
          .insert(reserva.toJson())
          .select()
          .single();

      // Devolver la reserva con el ID generado por la base de datos
      return Reserva.fromSupabase(response, reserva.articulo);

    } on PostgrestException catch (e) {
      throw Exception('Error al crear la reserva: ${e.message}');
    } catch (e) {
      throw Exception('Error desconocido al crear la reserva: $e');
    }
  }
}